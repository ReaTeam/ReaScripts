-- @description Toms tool
-- @author ak5k
-- @version 0.1.0
-- @about Isolates transients from selected items or Razor Edit ares, and adds filter and volume fades to resulting items (i.e. 'manual gating of toms'). See [website](https://forum.cockos.com/showthread.php?t=252563) for more information.

transient = 0.04 -- seconds
lead_pad = 0.01 -- seconds
decay_base = 0.666 * (3/2)-- seconds
filter_env_shape = -0.5
fade_shape = -0.707
clear_transient_guides = true

-------------------------------------------------------------------------------
local reaper = reaper

reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

local size = 4096
local samplebuffer = reaper.new_array(4*size)
local items = {}
local item_parents = {}
local chunk_cache = {}
local factors = {}
local filter_vals = {}
local has_filter = nil
local has_fade = nil

local function get_chunk(item)
  if not item then return nil end
  local item = item
  if not item_parents[item] then item_parents[item] = item end
  local item = item_parents[item]
  local retval = nil
  if not chunk_cache[item] then
    retval, chunk_cache[item] = reaper.GetItemStateChunk(item, "", false)
  else
    retval = true
  end
  if not retval then return nil end
  return chunk_cache[item]
end

local function get_tm_positions(item, pos, end_pos)
  local reaper = reaper
  if not item then return nil end
  local item = item
  local n = 1
  local res = {}
  local temp = nil
  
  local chunk = get_chunk(item)
  
  if not chunk then return nil end
  
  local take = reaper.GetActiveTake(item)
  local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local pos = pos or reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local end_pos = end_pos or reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + pos
  local take_number = 1 -- reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER") + 1
  
  for line in chunk:gmatch("TMINFO%s(%d+)") do
    res[n] = {}
    res[n][1] = tonumber(line)
    n = n + 1
  end

  if n == 1 then return nil end

  n = 1
  res[n][2] = {}
  for line in chunk:gmatch("TM%s(.-)\n") do
    res[n][2] = {}
    for substring in line:gmatch("%S+") do
       table.insert(res[n][2], tonumber(substring))
    end
    n = n + 1
  end

  --to absolute positions
  for i, tm_pos in ipairs(res[take_number][2]) do
    res[take_number][2][i-1] = res[take_number][2][i-1] or 0
    res[take_number][2][i] = tm_pos + res[take_number][2][i-1]
  end
  
  --to time positions
  n = 1
  for i, tm_pos in ipairs(res[take_number][2]) do
    res[take_number][2][i] = nil
    temp = tm_pos / res[take_number][1] - offset + pos

    if temp > pos and temp < end_pos then
      res[take_number][2][n] = temp
      n = n + 1
    end
  end
  
  res[take_number][2][0] = nil

  if #res[take_number][2] == 0 then return nil end
  return res[take_number][2]
end

local function analyze(item, pos, end_pos)
  local reaper = reaper
  local item = item
  local max, bin, hz, filter_val, factor = nil
  local pi = math.pi
  local log = math.log
  local cutoff = 300
  local numchannels = 1
  
  local tms = get_tm_positions(item, pos, end_pos)
  if not tms then return nil end
  
  local pos = pos or reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local starttime_sec = (starttime or tms[#tms]) - pos + transient
  
  local take = reaper.GetActiveTake(item)
  local source = reaper.GetMediaItemTake_Source(take)
  local samplerate = reaper.GetMediaSourceSampleRate(source)
  
  local accessor = reaper.CreateTakeAudioAccessor(take)
  samplebuffer.clear()
  local retval = reaper.GetAudioAccessorSamples(accessor, samplerate, numchannels, starttime_sec, 4*size, samplebuffer)
  reaper.DestroyAudioAccessor(accessor)
  
  if retval < 1 then return nil end
  
  local temp = samplebuffer.table()
  

  --"zero crossing"
  local n = 1
  while temp[n] > 0 do
    temp[n] = 0
    n = n + 1
  end
  n = n + 1
  while temp[n] < 0 do
    temp[n] = 0
    n = n + 1
  end
  n = #temp
  while temp[n] > 0 do
    temp[n] = 0
    n = n - 1
  end
  n = n - 1
  while temp[n] < 0 do
    temp[n] = 0
    n = n - 1
  end

  local lp_cut = 2 * pi * cutoff
  local lp_n = 1 / (lp_cut + 3*samplerate)
  local lp_b1 = (3*samplerate - lp_cut) * lp_n
  local lp_a0 = lp_cut * lp_n

  local lp_out
  for i, sp in ipairs(temp) do
    lp_out = 2*sp * lp_a0 + (lp_out or 0) * lp_b1
    lp_out = 2*lp_out * lp_a0 + (lp_out or 0) * lp_b1
    lp_out = 2*lp_out * lp_a0 + (lp_out or 0) * lp_b1
    lp_out = 2*lp_out * lp_a0 + (lp_out or 0) * lp_b1
    temp[i] = lp_out
  end

  samplebuffer.copy(temp)
  samplebuffer.fft(size, true)
  temp = samplebuffer.table()

  for i, v in ipairs(temp) do
    bin = bin or 1
    max = max or v
    if v > max and i < size then 
      bin = i
      max = v
    end
  end
  
  hz = (samplerate * bin) / (4*size)

  filter_val = -43.8433 + 14.5245 * log(hz)
  factor = 100 / hz
  if factor < 1/3 then factor = 1/3 end
  if factor > 3 then factor = 3 end
  return factor, filter_val, hz
end

local function trim_item(item, pos, end_pos)
  if not item then return nil end
  local reaper = reaper
  local item = item
  local res = {}
  local new_item = nil
  local pos = pos or reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  item = reaper.SplitMediaItem(item, pos) or item
  pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  res[item] = true
  --local pos = pos or reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local end_pos = end_pos or pos + len
  local mute = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
  reaper.SetMediaItemInfo_Value(item, "B_MUTE", 0)
  local factor, filter_val = analyze(item, pos, end_pos)
  reaper.SetMediaItemInfo_Value(item, "B_MUTE", mute)
  factors[item] = factor
  filter_vals[item] = filter_val
  local tms = get_tm_positions(item, pos, end_pos)
  if not tms then goto no_transients end
  for i = #tms, 1, -1 do
    if (tms[i+1] or end_pos) - tms[i] > decay_base * factor then
      new_item = reaper.SplitMediaItem(item, (tms[i+1] or end_pos) - lead_pad) or item
      item_parents[new_item] = item
      res[new_item] = true
    end
    if i == 1 then
      new_item = reaper.SplitMediaItem(item, tms[i] - lead_pad) or item
      item_parents[new_item] = item
      res[new_item] = true
    end
  end
  ::no_transients::
  for item, v in pairs(res) do
    tms = get_tm_positions(item)
    if not tms then
      res[item] = nil
      item_parents[item] = nil
      reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
    else
      pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      reaper.SetMediaItemInfo_Value(item, "D_LENGTH", tms[#tms] + factor * decay_base - pos)
      reaper.SetMediaItemInfo_Value(item, "B_MUTE", 0)
    end
  end
  return true
end

function set_fades(item)
  local item = item
  local tms = get_tm_positions(item)
  local pos_out = tms[#tms]
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local end_pos = len + pos
  local fadeout_len = (end_pos-pos_out)/2
  local fadein_len = lead_pad
  local buf, take_count, take, _, fx = nil
  has_filter = false
  has_fade = false
  local take_count = reaper.CountTakes(item)
  for i = 0, take_count -1 do
    take = reaper.GetMediaItemTake(item, i)
    for j = 0, reaper.TakeFX_GetCount(take) -1 do
      _, buf = reaper.TakeFX_GetFXName(take, j, "", 1)
      if buf == 'JS: simplelp6db' then
        has_filter = true
      end
    end
  end
  if reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN") == lead_pad then
    has_fade = true
  end
  if has_filter == false and has_fade == true then
    fadein_len = 0
    fadeout_len = 0
  end
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fadein_len) 
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadeout_len)
  reaper.SetMediaItemInfo_Value(item, "D_FADEINDIR", -1 * fade_shape)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", fade_shape)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", -1)
end

function set_filter(item)
  local item = item
  local tms = get_tm_positions(item)
  local pos_out = tms[#tms]
  local filter_val = filter_vals[item_parents[item]]
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local end_pos = len + pos
  local buf, take, _, take_count, fx, env
  local del = false
  local take_count = reaper.CountTakes(item)
  
  if has_filter == true and has_fade == true then
    for i = 0, take_count -1 do
      take = reaper.GetMediaItemTake(item, i)
      for j = 0, reaper.TakeFX_GetCount(take) -1 do
        _, buf = reaper.TakeFX_GetFXName(take, j, "", 1)
        if buf == 'JS: simplelp6db' then
          reaper.TakeFX_Delete(take, j)
        end
      end
      
    end
  end
  
  if has_filter == false and has_fade == false then
    take = reaper.GetActiveTake(item)
    --for j = 0, take_count -1 do
      --take = reaper.GetMediaItemTake(item, j)
      fx = reaper.TakeFX_AddByName(take, 'simplelp6db', 1)
      reaper.TakeFX_SetPresetByIndex(take, fx, -2)
      env = reaper.TakeFX_GetEnvelope(take, fx, 2, true)
      reaper.InsertEnvelopePoint(env, pos_out+transient-pos, 100, 5, filter_env_shape, false)
      reaper.InsertEnvelopePoint(env, end_pos - (end_pos-pos_out)/2 - pos, filter_val, 0, 0, false)
    --end
  end
end

local function parse_razor(buf)
  if not buf then return nil end
  local buf = buf
  local res = {}
  local i, j = 1, 1
  for w in buf:gmatch("%S+") do
    res[i] = res[i] or {}
    res[i][j] = res[i][j] or {}
    res[i][j] = tonumber(w) or w
    j = j + 1
    if j == 4 then 
      res[i][j-1] = w:match('%"(.-)%"') or ""
      j = 1
      i = i + 1
    end
  end
  if i == 1 then return nil end
  return res
end

local function get_razor()
  local res = {}
  local tr
  local buf = ""
  local retval
  local n = 1
  for i = 0, reaper.GetNumTracks() -1 do
    tr = reaper.GetTrack(0, i)
    retval, buf = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", buf, false)
    if retval and buf ~= "" then
      res[n] = {tr, parse_razor(buf)}
      n = n + 1
    end
  end
  if n == 1 then return nil end
  return res
end

local function get_razor_items(tr, parsed_razor)
  if not tr or not parsed_razor then return nil end
  local tr = tr
  local parsed_razor = parsed_razor
  local res = {}
  local n = 1
  for i = 0, reaper.CountTrackMediaItems(tr) -1 do
    local item = reaper.GetTrackMediaItem(tr, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local end_pos = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + pos
    for i = #parsed_razor, 1, -1 do
      local rz_edit = parsed_razor[i]
      if not (pos <= rz_edit[1] and end_pos <= rz_edit[1] or
        pos >= rz_edit[2] and end_pos >= rz_edit[2]) or 
        pos > rz_edit[1] and pos < rz_edit[2] or 
        end_pos > rz_edit[1] and end_pos < rz_edit[2] then
        res[n] = {}
        res[n] = {item, rz_edit[1], rz_edit[2]}
        n = n + 1
      end
    end
  end
  if n == 1 then return nil end
  return res
end

local function get_razor_transient_items(razor)
  if not razor then return nil end
  local razor = razor
  local res = {}
  local orig = {}
  local n = 1
  local razor_items = nil
  local item
  local item_count = reaper.CountSelectedMediaItems(0)
  
  for i = item_count -1, 0, -1 do
    item = reaper.GetSelectedMediaItem(0, i)
    reaper.SetMediaItemSelected(item, false)
  end
  
  for _, track_rz in ipairs(razor) do
    local tr = track_rz[1]
    local parsed_razor = track_rz[2]
    local razor_items = get_razor_items(tr, parsed_razor)
    if razor_items then
      for _, razor_item in ipairs(razor_items) do
        local item = razor_item[1]
        reaper.SplitMediaItem(item, razor_item[3])
        item = reaper.SplitMediaItem(item, razor_item[2]) or item
        reaper.SetMediaItemSelected(item, true)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local end_pos = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + pos
        res[n] = {item, pos, end_pos}
        n = n + 1
      end
    end
  end
  
  if n == 1 then return nil, nil end
  return res, orig
end

local retval, desc = reaper.GetAudioDeviceInfo("MODE", "")

if not retval then return end

local razor = get_razor()

items = get_razor_transient_items(razor)

if not items then
  items = {}
  local item_count = reaper.CountSelectedMediaItems(0)
  for i = 1, item_count do
    items[i] = {}
    items[i][1] = reaper.GetSelectedMediaItem(0, i -1)
    items[i][2] = reaper.GetMediaItemInfo_Value(items[i][1], "D_POSITION")
    items[i][3] = reaper.GetMediaItemInfo_Value(items[i][1], "D_LENGTH") + items[i][2]
  end
end

reaper.Main_OnCommandEx(42029, 0, 0)

for i, item in ipairs(items) do
  trim_item(item[1], item[2], item[3])
end

for item, parent in pairs(item_parents) do
  set_fades(item)
  set_filter(item)
end

if clear_transient_guides == true then
  reaper.Main_OnCommandEx(42027, 0, 0)
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Toms tool", 0)

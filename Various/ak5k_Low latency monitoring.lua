-- @description Low latency monitoring
-- @author ak5k
-- @version 1.6
-- @changelog Report window now shows monitored input tracks.
-- @link Forum thread, more detailed information https://forum.cockos.com/showthread.php?t=245445
-- @about
--   # Low latency monitoring
--
--   Provides REAPER a function also known as 'Low Latency Monitoring', 'Low Latency Mode', 'Native Low Latency Monitoring', 'Constrain Delay Compenstation' or 'Reduce Latency when Monitoring' in other DAWs. It resembles the one from Cubase.
--
--   While enabled, it bypasses (or takes offline) latency inducing plugins (VSTs etc) from rec armed, input monitored and automation write enabled signal chains, to provide lowest possible latency and CPU usage when monitoring through software.
--
--   Plugins contributing PDC latency to active signal chain will be bypassed, once the set limit is exceeded per signal chain. Useful when recording e.g. software synths or guitars through amp sims, or writing automation, into a REAPER project already filled with plugins.
--
--   Can be setup as a toolbar toggle on/off button, and this is recommended. Settings can be configured. REAPER 6.21 or later required. Visit [website](https://forum.cockos.com/showthread.php?t=245445) for detailed information or reporting bugs.

--Get settings from user:
local user_settings = true

local total_pdc_limit = 10 -- in ms
local enable_safe_tag = true -- or false
local safe_tag = "-LL"
local trackfx_pdc_limit = 0 -- in ms
local include_master = true -- or false
local enable_report = true -- or true
local enable_hard_limit = false -- or false
local pdc_manager = false -- or true

--might cause terrible horror and misery
local mixed_pdc = false
local hard_limit = 511

local ClearConsole = reaper.ClearConsole
local Undo_CanUndo2 = reaper.Undo_CanUndo2
local GetAudioDeviceInfo = reaper.GetAudioDeviceInfo
local GetInputOutputLatency = reaper.GetInputOutputLatency
local genGuid = reaper.genGuid
local GetMasterTrack = reaper.GetMasterTrack
local GetMediaTrackInfo_Value = reaper.GetMediaTrackInfo_Value
local GetNumTracks = reaper.GetNumTracks
local GetParentTrack = reaper.GetParentTrack
local GetProjExtState = reaper.GetProjExtState
local GetProjectStateChangeCount = reaper.GetProjectStateChangeCount
local GetTrack = reaper.GetTrack
local GetTrackGUID = reaper.GetTrackGUID
local GetTrackName = reaper.GetTrackName
local GetTrackNumSends = reaper.GetTrackNumSends
local GetTrackSendInfo_Value = reaper.GetTrackSendInfo_Value
local GetTrackState = reaper.GetTrackState
local GetTrackStateChunk = reaper.GetTrackStateChunk
local GetMediaTrackInfo_Value = reaper.GetMediaTrackInfo_Value
local PreventUIRefresh = reaper.PreventUIRefresh
local SetMediaTrackInfo_Value = reaper.SetMediaTrackInfo_Value
local SetTrackStateChunk = reaper.SetTrackStateChunk
local SetProjExtState = reaper.SetProjExtState
local SetProjExtState = reaper.SetProjExtState
local ShowConsoleMsg = reaper.ShowConsoleMsg
local TrackFX_AddByName = reaper.TrackFX_AddByName
local TrackFX_Delete = reaper.TrackFX_Delete
local TrackFX_GetCount = reaper.TrackFX_GetCount
local TrackFX_GetEnabled = reaper.TrackFX_GetEnabled
local TrackFX_GetFXGUID = reaper.TrackFX_GetFXGUID
local TrackFX_GetFXName = reaper.TrackFX_GetFXName
local TrackFX_GetParam = reaper.TrackFX_GetParam
local TrackFX_GetInstrument = reaper.TrackFX_GetInstrument
local TrackFX_GetNamedConfigParm = reaper.TrackFX_GetNamedConfigParm
local TrackFX_SetEnabled = reaper.TrackFX_SetEnabled
local TrackFX_SetOffline = reaper.TrackFX_SetOffline
local TrackFX_GetOffline = reaper.TrackFX_GetOffline
local TrackFX_SetParam = reaper.TrackFX_SetParam
local Undo_BeginBlock = reaper.Undo_BeginBlock
local Undo_EndBlock = reaper.Undo_EndBlock
local ValidatePtr = reaper.ValidatePtr
local concat = table.concat
local defer = reaper.defer
local find = string.find
local gmatch = string.gmatch
local gsub = string.gsub
local insert = table.insert
local sort = table.sort
local remove = table.remove
local format = string.format
local time_precise = reaper.time_precise
local unpack = table.unpack
local ceil = math.ceil
local floor = math.floor
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring

local message_name = "Low Latency Monitoring"
local section = "ak5k"
local key = "llm"
local extname = section .. key
local extkey_trackfx = "trackfx"
local extkey_hard = "hard"
local extkey_time_delayers = "time_delayers"
local extkey_path_stack = "path_stack"
local guid = extname --inital value
local master_track = GetMasterTrack(0)
local monitored_input_tracks = {}
local path_stack = {}
local path_stack0 = {}
local path_stack_diff = {}
local path_table = {}
local path_table0 = {}
local proj_graph = {}
local proj_graph0 = {}
local proj_trackfx = {}
local proj_trackfx0 = {}
local proj_size = -1
local proj_size0 = -1
--local proj_state = -1
--local proj_state0 = nil
local proj_tracks = {}
local total_latency = -1
local total_limit = -1
local trackfx_stack = {}
local trackfx_stack0 = {}
local trackfx_limit = -1
local base_latency = -1
local block_size = -1
local hard_stack = {}
local hard_stack0 = {}
local safe_stack = {}
local safe_stack0 = {}
local tsc_cache = {} 
local tsc_pool = {}
local sample_rate = -1
local results = {}
local print_results = {}
local report_base
local report_latency
local time_delayers = {}
local time_delayers0 = {}
local node_latencies = {}
local node_latencies0 = {}
local pdc_tsc_cache = {}
local sends_to_hw = {}
local sends_to_hw0 = {}
local pdc_graph = {}

reaper.gmem_attach("ak5k")

local function msg(string)
  --ClearConsole()
  ShowConsoleMsg(string .. '\n')
  return nil
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

local function clone(t)
  if not t then return nil end
  local res = {}
  for k, v in pairs(t) do
    res[k] = v
  end
  return res
end

local function lenght(t)
  local res = 0
  for _ in pairs(t) do res = res + 1 end
  return res
end

local function path_table_lenght(t)
  local res = 0
  for i = 1, #t do
    for j = 1, #t[i] do
      for k = 1, #t[i][j] do
        res = res + 1
      end
    end
  end
  return res
end

local function proj_diff(t1, t2)
  local len_t1 = lenght(t1)
  local len_t2 = lenght(t2)
  
  if len_t1 ~= len_t2 then
    return true
  end
  
  for k, t in pairs(t1) do
    if not t2[k] then return true end
    local len_t1 = lenght(t)
    local len_t2 = lenght(t2[k])
    if len_t1 ~= len_t2 then return true end
    for k2, v in pairs(t) do
      if t2[k][k2] ~= v then return true end
    end
  end
  return false
end

local function diff(t1, t2)
  local len_t1 = lenght(t1)
  local len_t2 = lenght(t2)
  
  if len_t2 > len_t1 then
    t1, t2 = t2, t1
  end
  
  for k, _ in pairs(t1) do
    if not t2[k] then
      return true
    end
  end
  return false
end

local function diff2(t1, t2)
  local len_t1 = lenght(t1)
  local len_t2 = lenght(t2)
  
  if len_t2 > len_t1 then
    t1, t2 = t2, t1
  end
  for k, v in pairs(t1) do
    if not t2[k] then return true end
    if t2[k] ~= v then return true end
  end
  return false
end

local function path_table_diff(t1, t2)
  local t1 = t1 or path_table
  local t2 = t2 or path_table0
  local len_t1 = path_table_lenght(t1)
  local len_t2 = path_table_lenght(t2)
  if len_t1 ~= len_t2 then return true end
  
  if len_t2 > len_t1 then
    t1, t2 = t2, t1
  end
  
  for i = 1, #t1 do
    for j = 1, #t1[i] do
      for k = 1, #t1[i][j] do
        if t1[i][j][k] ~= t2[i][j][k] then
          return true
        end
      end
    end
  end
  return false
end

local function list_to_csv(list)
  local res = {}
  local i = 1
  for k, v in pairs(list) do
    res[i] = k -- .. "," .. tostring(v)
    i = i + 1
  end
  return concat(res, ",")
end

local function csv_to_list(csv)
  local res = {}
  if csv == "" then return res end
  for fxguid in gmatch(csv, '[^,]+') do
    --local _, _, fxguid, pdc = find(pair, "(.-),(%d+)")
    res[fxguid] = true
  end
  return res
end

local function csv_to_idx_list(csv)
  local res = {}
  if csv == "" then return res end
  local i = 1
  for v in gmatch(csv, '[^,]+') do
    --local _, _, fxguid, pdc = find(pair, "(.-),(%d+)")
    res[i] = v
    i = i + 1
  end
  return res
end

-----------------------------------------

local function check_offset(tr)
  if pdc_manager == false then return nil end
  local offset = GetMediaTrackInfo_Value(tr, "I_PLAY_OFFSET_FLAG")
  if offset ~= 2 then
    SetMediaTrackInfo_Value(tr, "I_PLAY_OFFSET_FLAG", 2)
  end
end

local version = 0
local function set_version()
  local _, _
  version = reaper.GetAppVersion()
  _, _, version = find(version, "(%d+.%d+)")
  version = tonumber(version)
end

local function check_classic_pdc(tr)
  if version < 6.21 then return true end
  if mixed_pdc == false then return false end
  local _
  if not tsc_pool[tr] then
    _, tsc_pool[tr] = GetTrackStateChunk(tr, "")
  end
  local _, _, pdc_options = find(tsc_pool[tr], "\nPDC_OPTIONS%s(%d)\n")
  pdc_options = tonumber(pdc_options)
  if pdc_options == 0 then
    return true
  end
  return false
end

local function set_results(fxguid, pdc, block)
  if not enable_report then return nil end
  if pdc == 0 then return nil end
  results[proj_trackfx[fxguid][1]] = results[proj_trackfx[fxguid][1]] or {}
  local i = proj_trackfx[fxguid][2] + 1
  results[proj_trackfx[fxguid][1]][i] = {pdc, block, proj_trackfx[fxguid][6]}
end


local function set_report()
  report_latency = (1000 * total_latency / sample_rate)
  report_latency = format("%.1f", report_latency)
  report_latency = report_latency .. " ms"
  report_base = "Audio Device: "
  report_base = report_base .. format("%.1f", (1000 * base_latency / sample_rate))
  report_base = report_base .. " ms"
  local i, o = GetInputOutputLatency()
  report_base = report_base .. " IO "
  report_base = report_base .. tostring(i+o)
  report_base = report_base .. " spls"
  print_results = {}
  for tr, res in pairs(results) do
    print_results[tr] = {}
    local tot = 0
    local classic_pdc = check_classic_pdc(tr)
    for i, v in pairs(res) do
      local lat
      if classic_pdc then
        tot = tot + v[2]
        lat = v[2]
      else
        tot = v[2]
        lat = v[1]
      end
      local str = ""
      lat = (1000 * lat / sample_rate)
      str = str .. format("%.1f", lat)
      str = str .. " ms"
      str = str .. " ".. tostring(v[1]) .. "/" .. tostring(v[2]) .. " spls"
      str = str .. " " .. tostring(v[3])
      print_results[tr][i] = str
    end
    local _, trname = GetTrackName(tr)
    local lat = (1000 * tot / sample_rate)
    local str = format("%.1f", lat)
    str = trname .. " " .. str .. " ms"
    str = str .. " " .. tostring(tot) .. " spls"
    print_results[tr][0] = str
  end
  local n = 0
  for i, tr in ipairs(monitored_input_tracks) do
    print_results[i] = {}
    _, print_results[i][0] = GetTrackName(tr)
  end
end

local function draw_report()
  gfx.x, gfx.y = 16, 12
  gfx.drawstr(report_latency)
  local h = 12
  local h1 = 24
  gfx.x, gfx.y = 16, h1 + h
  gfx.drawstr(report_base)
  
  local i = 1
  for tr, v in pairs(print_results) do
    i = i + 1
    h1 = h1 + h
    local str = print_results[tr][0]
    --print_results[tr][0] = nil
    gfx.x, gfx.y = 16, h1 + h * i
    gfx.drawstr(str)
    for j, v in pairs(v) do
      if j ~= 0 then
        i = i + 1
        gfx.x, gfx.y = 32, h1 + h * i
        local str = tostring(j) .. " " .. print_results[tr][j]
        gfx.drawstr(str)
      end
    end
  end
  gfx.update()
end


local function check_audio_device()
  local input, output = GetInputOutputLatency()
  base_latency = input + output
  total_latency = base_latency
  local bool, srate = GetAudioDeviceInfo("SRATE", "")
  local bool, bsize = GetAudioDeviceInfo("BSIZE", "")
  if not bool then
    total_limit = 0
    trackfx_limit = 0
    hard_limit = hard_limit
    block_size = 0
    sample_rate = 44100
    return
  end
  sample_rate = srate
  block_size = tonumber(bsize)
  total_limit = floor(srate * (total_pdc_limit / 1000))
  trackfx_limit = floor(srate * (trackfx_pdc_limit / 1000))
  hard_limit = floor(srate / 44100) * hard_limit
end

local function verify_proj()
  local num, ext_state_guid = GetProjExtState(0, extname, "guid")
  if ext_state_guid ~= guid then
    guid = genGuid()
    SetProjExtState(0, extname, "guid", guid)
    return false
  end
  return true
end

local function write_state(extkey)
  local list
  if extkey == "trackfx" then
    list = trackfx_stack
  end
  if extkey == "hard" then
    list = hard_stack
  end
  if extkey == "time_delayers" then
    list = time_delayers
  end
  if extkey == "path_stack" then
    list = {}
    for node,_ in pairs(path_stack) do
      local guid = GetTrackGUID(node)
      list[guid] = true
    end
  end
  local csv = list_to_csv(list)
  return SetProjExtState(0, extname, extkey, csv)
end

local function read_state(extkey)
  local _, csv = GetProjExtState(0, extname, extkey)
  return csv_to_list(csv)
end

--global proj tracks
local function set_proj_tracks()
  if proj_size ~= proj_size0 then
    proj_tracks = {}
    for i = 1, proj_size do
      proj_tracks[i] = GetTrack(0, i - 1)
    end
    insert(proj_tracks, GetMasterTrack(0))
  end
  return nil
end

local function get_proj_tracks()
  local i = 0
  local n = #proj_tracks
  local k = 0
  return function()
    i = i + 1
    if i <= n and 
      ValidatePtr(proj_tracks[i], "MediaTrack*") then
      k = k + 1
      return k, proj_tracks[i]
    end
  end
end

--set graph from proj tracks
local function set_proj_graph()
  proj_graph = {}

  for i, node in get_proj_tracks() do
    proj_graph[node] = proj_graph[node] or {}
    
    local link = GetParentTrack(node)
    local send = GetMediaTrackInfo_Value(node, "B_MAINSEND")
  
    --
    if link and send ~= 0 then
      proj_graph[node][link] = true
    end
    
    --"track receives -1, "reverse links" "
    for j = 0, GetTrackNumSends(node, -1) -1 do --zero index -1
      local link = node
      local mute_state = GetTrackSendInfo_Value(link, -1, j, "B_MUTE")
      local node = GetTrackSendInfo_Value(link, -1, j, "P_SRCTRACK")
      if mute_state ~= 1 then
        proj_graph[node] = proj_graph[node] or {}
        proj_graph[node][link] = true
      end
    end
    
    --has link to master
    if not link and send ~= 0 and --then
      node ~= master_track then
      proj_graph[node] = proj_graph[node] or {}
      proj_graph[node][master_track] = true
    end
  end
  return nil
end

local function get_trackfx_info(tr, fx)
  local fxguid = TrackFX_GetFXGUID(tr, fx)
  local enabled = TrackFX_GetEnabled(tr, fx)
  local offline = TrackFX_GetOffline(tr, fx)
  local _, pdc = TrackFX_GetNamedConfigParm(tr, fx, "pdc")
  local _, name = TrackFX_GetFXName(tr, fx, "")
  pdc = tonumber(pdc)
  return fxguid, enabled, offline, pdc, name 
end

local function get_fx_hash(tr, fx)
  local _, res, temp
  _, res = reaper.TrackFX_GetFXName(tr, fx, "")
  for i = 0, reaper.TrackFX_GetNumParams(tr, fx) -1 do
    _, temp = reaper.TrackFX_GetParamName(tr, fx, i, "")
    res = res .. temp
    temp = reaper.TrackFX_GetParam(tr, fx, i)
    res = res .. tostring(temp)
  end
  return res
end

local function hunt_for_orphans()
  local trigger = Undo_CanUndo2(0)
  local state = false
  if trigger == "Copy FX" or
    trigger == "Duplicate tracks" then
    state = true 
  end
  if state == false then return nil end
  local parents = {}
  for fxguid, _ in pairs(trackfx_stack0) do
    local tr = proj_trackfx[fxguid][1]
    local fx = proj_trackfx[fxguid][2]
    parents[get_fx_hash(tr, fx)] = true
  end
  for fxguid, _ in pairs(hard_stack0) do
    local tr = proj_trackfx[fxguid][1]
    local fx = proj_trackfx[fxguid][2]
    parents[get_fx_hash(tr, fx)] = true
  end
  
  for fxguid, info in pairs(proj_trackfx) do
    if not trackfx_stack0[fxguid] or
      not hard_stack0[fxguid] then
      local enabled, offline = info[3], info[4]
      if not enabled or offline then
        local hash = get_fx_hash(info[1], info[2])
        if parents[hash] then
          if not enabled then
            trackfx_stack0[fxguid] = true
          elseif offline and enable_hard_limit == true then
            hard_stack0[fxguid] = true
          end
          if trigger == "Duplicate tracks" and
            not path_stack[info[1]] then
              trackfx_stack0[fxguid] = nil
          end
        end
      end
    end
  end
end    

local function set_proj_trackfx()
  proj_trackfx = {}
  for _, tr in get_proj_tracks() do
  for fx = 0, TrackFX_GetCount(tr) -1 do
    local _
    local fxguid, enabled, offline, pdc, name = 
        get_trackfx_info(tr, fx)
    proj_trackfx[fxguid] = {}
    proj_trackfx[fxguid] = {tr, fx, enabled, offline, pdc, name}
  end
  end
end
    
--get paths for node
local function get_paths(node, res, path, n)
  local res = res or {}
  local path = path or {}
  local n = n or 1
  
  --end reached
  if not proj_graph[node] or 
    lenght(proj_graph[node]) == 0 then
    path[n] = node
    insert(res, path)
    return res
  end
  
  --feedback loop
  for i = 1, #path do
    if node == path[i] then
      insert(res, path)
      return res
    end
  end
  
  path[n] = node

  local n_links = lenght(proj_graph[node])  
  
  --create new_paths for splits
  local new_path = {}
  if n_links > 1 then
    
  for i = 2, n_links do
    new_path[i] = clone(path)
  
  end
  end
  
  local i = 1
  for link, _ in pairs(proj_graph[node]) do
    if i > 1 then
      path = new_path[i]
    end
    res = get_paths(link, res, path, n + 1)
    i = i + 1
  end
  
  return res
end

--set global path table
local function set_path_table()
  path_table = {}
  local nodes = monitored_input_tracks
  for i = 1, #nodes do
    path_table[i] = get_paths(nodes[i])
  end
  return nil
end

local function set_path_stack()
  path_stack = {}
  
  for i = 1, #path_table do
  
  for j = 1, #path_table[i] do
  
  for k =1, #path_table[i][j] do
    path_stack[path_table[i][j][k]] = true
  
  end
  end
  end
  
  for node, _ in pairs(path_stack) do
    for j = 0, GetTrackNumSends(node, 1) -1 do
      local mute_state = GetTrackSendInfo_Value(node, 1, j, "B_MUTE")
      if mute_state ~= 1 then
        sends_to_hw[node] = true
      end
    end
  end
  
  for i = #path_table,1,-1 do
  
  for j = #path_table[i],1,-1 do
    if not sends_to_hw[path_table[i][j][#path_table[i][j]]] then
      table.remove(path_table[i],j)
    end
  end
  end
end

local function set_monitored_input_tracks()
  monitored_input_tracks = {}
  
  local n = 1
  for _, track in ipairs(proj_tracks) do
  
  local bool, flags = GetTrackState(track)
  
  if glob_autom_over[1] > 1 or 
    reaper.GetTrackAutomationMode(track) > 1 or
    bool and
    (flags & 64) ~= 0 and
    (flags & 128) ~= 0 or
    (flags & 256) ~= 0 then
    monitored_input_tracks[n] = track
    
    n = n + 1
    
  end
  
  end
end

local function filter_data(fxguid, res)
  local res = res
  
  local enabled = proj_trackfx[fxguid][3]
  local offline = proj_trackfx[fxguid][4]
  local pdc_orig = proj_trackfx[fxguid][5]
  local pdc = pdc_orig
  if not pdc_manager then
    local pdc = ceil(pdc_orig / block_size) * block_size
  end
  
  if hard_stack[fxguid] then
    return res
  end
  
  if pdc < trackfx_limit then
    set_results(fxguid, pdc_orig, pdc)
    return res + pdc
  end
  
  enabled = enabled and not offline
  
  if include_master ~= true and
    proj_trackfx[fxguid][1] == master_track then
      set_results(fxguid, pdc_orig, pdc)
      if enabled then
        return res
      else
        return res
      end
  end
   
  if safe_stack[fxguid] then
    set_results(fxguid, pdc_orig, pdc)
    if enabled then
      return res + pdc
    else
      return res
    end
  end
  
  
  if enabled then --trackfx contributes
    if pdc > 0 and res + pdc > total_limit then
      trackfx_stack[fxguid] = true -- {tr, fx}
      trackfx_stack0[fxguid] = nil
    else
      set_results(fxguid, pdc_orig, pdc)
      res = res + pdc
    end
  end
  
  if enabled and trackfx_stack0[fxguid] then
    set_results(fxguid, pdc_orig, pdc)
    return res + pdc
  end

  --should previously disabled plugin stay disabled?
  if not enabled and trackfx_stack0[fxguid] then
    if pdc > 0 and res + pdc > total_limit then
      trackfx_stack[fxguid] = trackfx_stack0[fxguid]
    end
  end
  
  return res

end

local function filter_fxchain(tr, res)
  local midsum = 0
  for fx = 0, TrackFX_GetCount(tr) -1 do
  
  local fxguid = TrackFX_GetFXGUID(tr, fx)
  local enabled = proj_trackfx[fxguid][3]
  local offline = proj_trackfx[fxguid][4]
  local pdc = proj_trackfx[fxguid][5]
  
  local current = ceil((midsum + pdc) / block_size) * block_size
  
  enabled = enabled and not offline
  
  if enabled and not hard_stack[fxguid] then --trackfx contributes
    if include_master ~= true and
      proj_trackfx[fxguid][1] == master_track then
      midsum = midsum
      trackfx_stack[fxguid] = nil
      set_results(fxguid, pdc, current)
    elseif safe_stack[fxguid] then
      midsum = midsum + pdc
      trackfx_stack[fxguid] = nil
      set_results(fxguid, pdc, current)
    elseif include_master ~= true and
      proj_trackfx[fxguid][1] == master_track then
      midsum = midsum
      trackfx_stack[fxguid] = nil
      set_results(fxguid, pdc, current)
    elseif res + current < total_limit then
      set_results(fxguid, pdc, current)
      midsum = midsum + pdc
    elseif pdc < trackfx_limit then
      set_results(fxguid, pdc, current)
      midsum = midsum + pdc
    elseif pdc > 0 then
      trackfx_stack[fxguid] = true -- {tr, fx}
      trackfx_stack0[fxguid] = nil
    end
  end
  
  if not enabled and trackfx_stack0[fxguid] then
    if pdc > 0 and res + current > total_limit then
      trackfx_stack[fxguid] = trackfx_stack0[fxguid]
    end
  end
   
  end
  res = res + ceil(midsum / block_size) * block_size
  return res
end

--node (track) data is individual trackfx
local function filter_node(node, res)
  if not ValidatePtr(node, "MediaTrack*") then
    return res
  end
  local res = res
  
  if check_classic_pdc(node) or pdc_manager then 
    for fx = 0, TrackFX_GetCount(node) -1 do
      local fxguid = TrackFX_GetFXGUID(node, fx)
      res = filter_data(fxguid, res)
    end
  else
    res = filter_fxchain(node, res)
  end
  return res
end

local function filter_path(path)
  local res = base_latency
  for i = 1, #path do 
    res = filter_node(path[i], res)
    if res > total_latency then
        total_latency = res
    end
  end
  return nil
end

local function filter_path_table()
  trackfx_stack = {}
  for i = 1, #path_table do
  
  for j = 1, #path_table[i] do
    filter_path(path_table[i][j])
  
  end
  end
  return nil
end

local function enable(tr, fx)
  fx = fx - 1
  if enable_hard_limit then
    TrackFX_SetOffline(tr, fx, false)
  end
  TrackFX_SetEnabled(tr, fx, true)
end

local function disable(tr, fx)
  fx = fx - 1
  TrackFX_SetEnabled(tr, fx, false)
  if enable_hard_limit then
    TrackFX_SetOffline(tr, fx, true)
  end
end

local function check_for_safe_tags()
end

local function set_hard_stack()
  if not enable_hard_limit then return nil end
  hard_stack = {}
  for fxguid, t in pairs(proj_trackfx) do
    local offline, pdc = t[4], t[5]
    local name = t[6]
    if not offline and 
      pdc > hard_limit and 
      not safe_stack[fxguid] and 
      not find(name, "Universal Audio", 1, true) then
      hard_stack[fxguid] = true
      hard_stack0[fxguid] = nil
    end
    if not safe_stack[fxguid] and
      offline and
      hard_stack0[fxguid] and --previously hard offlined
      pdc == 0 then --still offline
        hard_stack[fxguid] = true
    end
    if include_master ~= true and
      proj_trackfx[fxguid][1] == master_track then
      hard_stack[fxguid] = nil
    end
  end
end 

local function set_safe_stack()
  if not enable_safe_tag then return nil end
  safe_stack = {}
  for fxguid, t in pairs(proj_trackfx) do
    local name = t[6]
    local _, trname = GetTrackName(t[1])
    if enable_safe_tag and
      ends_with(name, safe_tag) or 
      ends_with(trname, safe_tag) then
      safe_stack[fxguid] = true
    end
    local vsti = TrackFX_GetInstrument(t[1])
    if vsti > -1 then
      safe_stack[TrackFX_GetFXGUID(t[1], vsti)] = true
    end
  end
end

local function tag_pdc_manager(tr, state)
  local _
  if not ValidatePtr(tr, "MediaTrack*") then
    return nil
  end
  if not pdc_tsc_cache[tr] then
    _, pdc_tsc_cache[tr] = GetTrackStateChunk(tr, "")
  end
  local chunk = pdc_tsc_cache[tr]
  
  local pdc_options = "PDC_OPTIONS 2\n"
  if state == false then
    pdc_options = ""
  end
  
  if chunk:find("PDC_OPTIONS%s%d\n") then
    chunk = chunk:gsub("PDC_OPTIONS%s%d\n", pdc_options, 1)
  else
    chunk = chunk:gsub("DOCKED%s(%d)\n", "DOCKED %1\n" .. pdc_options, 1)
  end
 pdc_tsc_cache[tr] = chunk
end

local function get_fxchain_pdc(tr)
  local res = 0
  for fx = 0, TrackFX_GetCount(tr) -1 do
    local fxguid = TrackFX_GetFXGUID(tr, fx)
    if not time_delayers[fxguid] then
      local enabled = proj_trackfx[fxguid][3]
      local offline = proj_trackfx[fxguid][4]
      enabled = enabled and not offline
      if enabled then
        local _, pdc = TrackFX_GetNamedConfigParm(tr, fx, "pdc")
        res = res + pdc
      end
    end
  end
  return res
end

--measure latencies
local function set_node_latencies(node, cor, target, path, pdc, n)
  if version < 6.21 or pdc_manager ~= true then return nil end
  local pdc = pdc or 0
  local root = root or node
  local path = path or {}
  local n = n or 1
  local cor = cor
  
  if target and
    node == target then
    pdc = pdc + cor
  end
  
  pdc = pdc + get_fxchain_pdc(node)
  if not node_latencies[node] or
    pdc > node_latencies[node] then
      node_latencies[node] = pdc
  end
  
  --end reached
  if lenght(proj_graph[node]) == 0 then
    return nil
  end
  
  --feedback loop
  for i = 1, #path do
    if node == path[i] then
      return nil
    end
  end
  
  path[n] = node

  local n_links = lenght(proj_graph[node])  
  
  --create new_paths for splits
  local new_path = {}
  if n_links > 1 then
    
  for i = 2, n_links do
    new_path[i] = clone(path)
  
  end
  end
  
  local i = 1
  for link, _ in pairs(proj_graph[node]) do
    if i > 1 then
      path = new_path[i]
    end
    set_node_latencies(link, cor, target, path, pdc, n + 1)
    i = i + 1
  end
  
  return nil
end

local function sort_links(t1, t2)
  return t1[2] > t2[2]
end

local function set_pdc_graph()
  --build reverse graph
  if pdc_manager ~= true or version < 6.21 then return nil end
  pdc_graph = {}
  for node, _ in pairs(path_stack) do
    pdc_graph[node] = pdc_graph[node] or {}
    for j = 0, GetTrackNumSends(node, -1) -1 do --zero index -1
      local mute_state = GetTrackSendInfo_Value(node, -1, j, "B_MUTE")
      local link = GetTrackSendInfo_Value(node, -1, j, "P_SRCTRACK")
      if mute_state ~= 1 and path_stack[link] then
        pdc_graph[node][link] = true
      end
    end
    
    local link = GetParentTrack(node)
    local send = GetMediaTrackInfo_Value(node, "B_MAINSEND")
  
    for j = 0, GetTrackNumSends(node, 1) -1 do
      local mute_state = GetTrackSendInfo_Value(node, 1, j, "B_MUTE")
      if mute_state ~= 1 then
        sends_to_hw[node] = true
      end
    end
     
    if link and send ~= 0 then
      pdc_graph[link] = pdc_graph[link] or {}
      pdc_graph[link][node] = true
    end
    if not link and send ~= 0 and
      node ~= master_track then
      pdc_graph[master_track] = pdc_graph[master_track] or {}
      pdc_graph[master_track][node] = true
    end
  end
end

local function set_pdc_manager(state)
  if pdc_manager ~= true or version < 6.21 then return nil end
  --reaper.gmem_write(1, 1)
  reaper.SetGlobalAutomationOverride(0)
  --set pdc off for monitored signal chain
  pdc_tsc_cache = {}
  if diff(path_stack, path_stack0) then
    for tr,_ in pairs(path_stack) do
      if not path_stack0[tr] then
        tag_pdc_manager(tr, true)
      end
    end
    for tr,_ in pairs(path_stack0) do
      if not path_stack[tr] then
        tag_pdc_manager(tr, false)
      end
    end
    --flush changes
    local n = lenght(pdc_tsc_cache)
    if n > 0 then
      PreventUIRefresh(n)
      for tr, chunk in pairs(pdc_tsc_cache) do
        SetTrackStateChunk(tr, chunk)
      end
      PreventUIRefresh(-n)
    end
  end
  
  if state == false then
    for tr,_ in pairs(path_stack0) do
      tag_pdc_manager(tr, false)
    end
    local n = lenght(pdc_tsc_cache)
    if n > 0 then
      PreventUIRefresh(n)
      for tr, chunk in pairs(pdc_tsc_cache) do
        SetTrackStateChunk(tr, chunk)
      end
      PreventUIRefresh(-n)
    end
  end
  
  
  local node_latencies_temp = clone(node_latencies)
  node_latencies = {}
  for i = 1, #monitored_input_tracks do
    set_node_latencies(monitored_input_tracks[i])
  end
  
  local node_cor = {}
  local sends_to_hw_cor = {}
  local i = 1
  for node, _ in pairs(sends_to_hw) do
    if node ~= master_track and
      path_stack[node] then
      sends_to_hw_cor[i] = {node, node_latencies[node]}
      i = i + 1
    end
  end
  
  sort(sends_to_hw_cor, sort_links)
  for i = 2, #sends_to_hw_cor do
     node_cor[sends_to_hw_cor[i][1]] = node_cor[sends_to_hw_cor[i][1]] or 0
    local cor = (sends_to_hw_cor[1][2] - sends_to_hw_cor[i][2])
    node_cor[sends_to_hw_cor[i][1]] = node_cor[sends_to_hw_cor[i][1]] + cor
    for node, _ in pairs(path_stack) do
      set_node_latencies(node, cor, sends_to_hw_cor[i][1])
    end
  end
  
  for node, links in pairs(pdc_graph) do
    local temp = {}
    for link, _ in pairs(links) do
      insert(temp, {link, node_latencies[link]})
    end
    sort(temp, sort_links)
    for i = 2, #temp do
      node_cor[temp[i][1]] = node_cor[temp[i][1]] or 0
      local correction = (temp[1][2] - temp[i][2])
      node_cor[temp[i][1]] = node_cor[temp[i][1]] + correction
      node_latencies[temp[i][1]] = node_latencies[temp[i][1]] + correction
    end
  end
  
  node_latencies = clone(node_latencies_temp)
  
  for node, cor in pairs(node_cor) do
    if cor == 0 then
      node_cor[node] = nil
    end
  end
  
  time_delayers0 = time_delayers
  time_delayers = {}
  PreventUIRefresh(1)
  for node, cor in pairs(node_cor) do
    local tr = node
    local temp = {}
    local n_chans = GetMediaTrackInfo_Value(tr, "I_NCHAN")
    n_chans = n_chans / 2
    local n_delayers = 0
    for fx = 0, TrackFX_GetCount(tr) -1 do
      local _, name = TrackFX_GetFXName(tr, fx, "")
      if name == "JS: time_adjustment" then
        n_delayers = n_delayers + 1
        local fxguid =  TrackFX_GetFXGUID(tr, fx)
        temp[fxguid] = true
        proj_trackfx[fxguid] = {tr, fx, true, false, 0, "JS: time_adjustment"}
      end
    end
    if n_chans ~= n_delayers then
      n_delayers = 0
      for fx = TrackFX_GetCount(tr) -1, 0, -1 do
        local _, name = TrackFX_GetFXName(tr, fx, "")
        if name == "JS: time_adjustment" then
          local fxguid =  TrackFX_GetFXGUID(tr, fx)
          temp[fxguid] = nil
          proj_trackfx[fxguid] = nil
          TrackFX_Delete(tr, fx)
        end
      end
      for i = 1, n_chans - n_delayers do
        local fx = TrackFX_AddByName(tr, "time_adjustment", false, -1)
        local fxguid =  TrackFX_GetFXGUID(tr, fx)
        temp[fxguid] = true
        proj_trackfx[fxguid] = {tr, fx, true, false, 0, "JS: time_adjustment"}
        reaper.TrackFX_SetPinMappings(tr, fx, 0, 0, 0, 0)
        reaper.TrackFX_SetPinMappings(tr, fx, 0, 1, 0, 0)
        reaper.TrackFX_SetPinMappings(tr, fx, 1, 0, 0, 0)
        reaper.TrackFX_SetPinMappings(tr, fx, 1, 1, 0, 0)
        if i < 17 then
          local pin1 = 1<<(2*i-2)
          local pin2 = 1<<(2*i-1)
          reaper.TrackFX_SetPinMappings(tr, fx, 0, 0, pin1, 0)
          reaper.TrackFX_SetPinMappings(tr, fx, 0, 1, pin2, 0)
          reaper.TrackFX_SetPinMappings(tr, fx, 1, 0, pin1, 0)
          reaper.TrackFX_SetPinMappings(tr, fx, 1, 1, pin2, 0)
        else
          local pin1 = 1<<(2*(i-16)-2)
          local pin2 = 1<<(2*(i-16)-1)
          reaper.TrackFX_SetPinMappings(tr, fx, 0, 0, 0, pin1)
          reaper.TrackFX_SetPinMappings(tr, fx, 0, 1, 0, pin2)
          reaper.TrackFX_SetPinMappings(tr, fx, 1, 0, 0, pin1)
          reaper.TrackFX_SetPinMappings(tr, fx, 1, 1, 0, pin2)
        end
      end
    end
    for fxguid, _ in pairs(temp) do
      time_delayers[fxguid] = true
      local tr = proj_trackfx[fxguid][1]
      local fx = proj_trackfx[fxguid][2]
      --local delay = TrackFX_GetParam(tr, fx, 3)
      --if delay ~= cor then
        TrackFX_SetParam(tr, fx, 0, 0)
        TrackFX_SetParam(tr, fx, 1, 0)
        TrackFX_SetParam(tr, fx, 2, -120)
        TrackFX_SetParam(tr, fx, 3, cor)
        TrackFX_SetParam(tr, fx, 4, 0)
        TrackFX_SetParam(tr, fx, 5, 1)
      --end
    end
  end
  
  --clear old delayers
  for _, tr in get_proj_tracks() do
    for fx = TrackFX_GetCount(tr) -1, 0, -1 do
      local fxguid = TrackFX_GetFXGUID(tr, fx)
      
      if time_delayers0[fxguid] and
        not time_delayers[fxguid] then
        TrackFX_Delete(tr, fx)
      end
    end
  end
  
  --destroy all delayers
  if state == false then
    for _, tr in get_proj_tracks() do
      for fx = TrackFX_GetCount(tr) -1, 0, -1 do
        local fxguid = TrackFX_GetFXGUID(tr, fx)
        if time_delayers[fxguid] or 
          time_delayers0[fxguid] then
          TrackFX_Delete(tr, fx)
        end
      end
    end
  end
  reaper.SetGlobalAutomationOverride(glob_autom_over[1])
  PreventUIRefresh(-1)
  
  write_state(extkey_time_delayers)
end

local function sync_state()
  check_audio_device()
  proj_size0 = proj_size
  proj_size = GetNumTracks()
  master_track = GetMasterTrack(0)
  set_proj_tracks()
  
  sends_to_hw0 = sends_to_hw
  sends_to_hw = {}
  proj_graph0 = proj_graph
  set_proj_graph()
  
  proj_trackfx0 = proj_trackfx
  set_proj_trackfx()
  
  set_monitored_input_tracks()
  
  path_table0 = path_table
  set_path_table()
  
  path_stack0 = path_stack
  set_path_stack()
  
  set_pdc_graph()
  
  safe_stack0 = safe_stack
  hard_stack0 = hard_stack
  trackfx_stack0 = trackfx_stack
  
  node_latencies0 = node_latencies
  node_latencies = {}
  for i = 1, #monitored_input_tracks do
    set_node_latencies(monitored_input_tracks[i])
  end
  
  if not verify_proj() then
    trackfx_stack0 = read_state(extkey_trackfx)
    hard_stack0 = read_state(extkey_hard)
    time_delayers = read_state(extkey_time_delayers) --!!!
    local path_stack_temp = read_state(extkey_path_stack)
    for guid, _ in pairs(path_stack_temp) do
      for _, tr in get_proj_tracks() do
        if GetTrackGUID(tr) == guid then
          path_stack0[tr] = true
        end
      end
    end
  end
  
  results = {}
  
  hunt_for_orphans()
end

local function process_trackfx(shutdown)
  --reaper.gmem_write(1, 1)
  reaper.SetGlobalAutomationOverride(0)

  for fxguid, t in pairs(proj_trackfx) do
  
  local tr = t[1]
  local fx = t[2]
  
  if trackfx_stack[fxguid] and
    not trackfx_stack0[fxguid] then
      TrackFX_SetEnabled(tr, fx, false)
  end
  if trackfx_stack0[fxguid] and
    not trackfx_stack[fxguid] then -- or
      TrackFX_SetEnabled(tr, fx, true)
  end
  
  if hard_stack[fxguid] and
    not hard_stack0[fxguid] then
    TrackFX_SetOffline(tr, fx, true)
  end
  if hard_stack0[fxguid] and
    not hard_stack[fxguid] then -- or
      TrackFX_SetOffline(tr, fx, false)
  end
  
  if shutdown then
    if hard_stack0[fxguid] then
        TrackFX_SetOffline(tr, fx, false)
    end 
    if trackfx_stack0[fxguid] then
        TrackFX_SetEnabled(tr, fx, true)
    end
  end
  
  end
  
  reaper.SetGlobalAutomationOverride(glob_autom_over[1])

  write_state(extkey_hard)
  write_state(extkey_trackfx)
  write_state(extkey_path_stack)
end


local function shutdown()
  Undo_BeginBlock()
  if enable_report then
    gfx.quit()
  end
  local shutdown = true
  process_trackfx(shutdown)
  set_pdc_manager(false)
  SetProjExtState(0, extname, "", "")
  Undo_EndBlock(message_name .. " Shutdown", 2)
end

--agb_max = 0
--atime_max = 0

proj_state = {}
glob_autom_over = {}

local function main()
  --atime0 = time_precise()
  --if reaper.gmem_read(0) ~= 0 then reaper.gmem_write(0, 0) end
  
  glob_autom_over[0] = glob_autom_over[1]
  glob_autom_over[1] = reaper.GetGlobalAutomationOverride()
  
  proj_state[0] = proj_state[1]
  proj_state[1] = GetProjectStateChangeCount()
  
  if proj_state[0] ~= proj_state[1] or 
    glob_autom_over[0] ~= glob_autom_over[1] then
  
  sync_state()
  
  set_safe_stack()
  
  if diff2(node_latencies, node_latencies0) or
    diff(sends_to_hw, sends_to_hw0) or 
    proj_diff(proj_trackfx, proj_trackfx0) or 
    proj_diff(proj_graph, proj_graph0) or 
    proj_diff(path_table, path_table0) or
    diff(safe_stack, safe_stack0) then 
  
  set_hard_stack()
  filter_path_table()
  
  if enable_report then set_report() end
  
  if diff(sends_to_hw, sends_to_hw0) or 
    diff2(node_latencies, node_latencies0) or
    diff(hard_stack0, hard_stack) or
    diff(trackfx_stack, trackfx_stack0) then 
  
  PreventUIRefresh(1)
  Undo_BeginBlock()
  
  --reaper.gmem_write(0, 1)
  
  process_trackfx()
  set_pdc_manager(pdc_manager)
  
  Undo_EndBlock(message_name, 2)
  PreventUIRefresh(-1)
  end
  
  
  end
  end
  
  --atime1 = time_precise()
  --atime = atime1 - atime0
  --atime = tonumber(string.format("%.3f", atime))
  --if atime > atime_max then atime_max = atime end
  --gb = collectgarbage("count")
  --if gb > agb_max then agb_max = gb end
  
  if enable_report then draw_report() end
  is_new_value, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
  
  if is_new_value then
    return
  end
  
  defer(main)
end

set_version()

if version < 6.21 then
  reaper.ShowConsoleMsg("ak5k_Low latency monitoring\n")
  reaper.ShowConsoleMsg("REAPER 6.21 or later required\n")
  return
end

local function get_user_settings()
  local title = message_name
  local num_inputs = 7
  local captions_csv = 
  "Latency limit: (in ms)," ..
  "Safe tagging: (1=yes, 0=no)," ..
  "Safe tag: (e.g. -LL)," ..
  "Plugin limit: (in ms)," ..
  "Include master: (1=yes, 0=no)," ..
  "Enable report: (1=yes, 0=no)," ..
  "Hard limit: (1=yes, 0=no)," --..
  --"PDC manager: (1=yes, 0=no),"
  
  --reaper.SetExtState(section, key, "", true)

  local retvals_csv = reaper.GetExtState(section, key)
  
  if retvals_csv == "" then
    retvals_csv =
    tostring(version) .. "," ..
    "1," ..
    "-LL," ..
    "0.0," ..
    "1," ..
    "1," ..
    "0," --..
    --"0,"
  end

  local retval, retvals_csv = reaper.GetUserInputs(title, num_inputs, captions_csv, retvals_csv)

  if not retval then
    return retval
  end
  
  local list = csv_to_idx_list(retvals_csv)
  for i = 1, #list do
    if i ~= 3 then --omit safe tag string
      list[i] = tonumber(list[i])
    end
  end
  total_pdc_limit = list[1]
  
  enable_safe_tag = false
  if list[2] == 1 then
    enable_safe_tag = true
  end
  
  safe_tag = "-LL"
  if list[3] ~= "" then
    safe_tag = list[3]
  end
  
  trackfx_pdc_limit = list[4]
  
  include_master = false
  if list[5] == 1 then
    include_master = true
  end
  
  enable_report = false
  if list[6] == 1 then
    enable_report = true
  end
  
  enable_hard_limit = false
  if list[7] == 1 then
    enable_hard_limit = true
  end
  
  pdc_manager = false
  if list[8] == 1 then
    pdc_manager = true
  end
  retvals_csv = reaper.SetExtState(section, key, retvals_csv, true)
  return true
end


if user_settings then 
  local state = false
  state = get_user_settings()
  if not state then
    return
  end
end

local function turn_on()
  local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  local state = reaper.GetToggleCommandStateEx( sec, cmd )
  reaper.SetToggleCommandState( sec, cmd, 1 ) -- Set ON
  reaper.RefreshToolbar2( sec, cmd )
end

local function turn_off()
  shutdown()
  local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  local state = reaper.GetToggleCommandStateEx( sec, cmd )
  reaper.SetToggleCommandState( sec, cmd, 0 ) -- Set OFF
  reaper.RefreshToolbar2( sec, cmd )
end

if version < 6.21 then pdc_manager = false end

turn_on()

if enable_report then
  gfx.init("LLM", 90, 30, 0, 200, 1000)
end

main()

reaper.atexit(turn_off)

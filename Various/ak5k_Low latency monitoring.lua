-- @description Low latency monitoring
-- @author ak5k
-- @version 2.1.1
-- @changelog
--   Fixed possible crash with feedback loop routing.
--
--   Fixed possible crash when changing projects while script is running.
--
--   Refactoring and performance optimization.
-- @link Forum thread, more detailed information https://forum.cockos.com/showthread.php?t=245445
-- @screenshot https://i.imgur.com/iKHyQXb.gif
-- @about
--   # Low latency monitoring
--
--   Provides REAPER a function also known as 'Low Latency Monitoring', 'Low Latency Mode', 'Native Low Latency Monitoring', 'Constrain Delay Compenstation' or 'Reduce Latency when Monitoring' in other DAWs. It resembles the one from Cubase.
--
--   While enabled, it bypasses (or takes offline) latency inducing plugins (VSTs etc) from rec armed, input monitored and automation write enabled signal chains, to provide lowest possible latency and CPU usage when monitoring through software.
--
--   Plugins contributing PDC latency to active signal chain will be bypassed, once the set limit is exceeded per signal chain. Useful when recording e.g. software synths or guitars through amp sims, or writing automation, into a REAPER project already filled with plugins.
--
--   Can be setup as a toolbar toggle on/off button, and this is recommended. REAPER 6.21 or later required. Visit [website](https://forum.cockos.com/showthread.php?t=245445) for detailed information or reporting bugs.

local collectgarbage = collectgarbage
local next = next
local pairs = pairs
local reaper = reaper
local tonumber = tonumber
local type = type

local limit = 0 --spls, unused
local bsize = 0

local state = {
  cache = {},
  inputTracks = {},
  network = {},
  tracks = {},
  trackFXs = {},
  trackFXsToEnable = {},
  trackFXsToDisable = {},
  trackFXsDisabled = {},
  trackFXsSafe = {},
  route = {},
  stack = {},
  temp = {}
}

local function ClearTable(t)
  for k in pairs(t) do
    if type(t[k]) == "table" then
      t[k] = ClearTable(t[k])
    else
      t[k] = nil
    end
  end
  return t
end

local function ClearTableX(t)
  local S = state.stack
  if t == S then
    local n = 0
    for k in pairs(S) do
      S[k] = nil
    end
    return t
  end
  
  if t == state.trackFXs or t == state.cache then
    for k in pairs(t) do
      t[k][1], t[k][2] = nil, nil
    end
    return t
  end
  
  S[#S+1] = t
  while #S > 0 do
    local f = #S
    local t = S[#S]
    for k in pairs(t) do
      if type(t[k]) == "table" then
        local w = t[k]
        if not S[w] then
          S[w] = true
          S[#S+1] = w
        end
      else
        t[k] = nil
      end
    end
    if f == #S then
      S[#S] = nil
    end
  end
  
  for k in pairs(S) do
    S[k] = nil
  end
  
  return t
end

local function UpdateState()
  local inputTracks = ClearTable(state.inputTracks) -- {}
  local network = ClearTable(state.network) -- {}
  local tracks = ClearTable(state.tracks)
  local trackFXs = ClearTable(state.trackFXs) -- {}
  local retval
  retval, bsize = reaper.GetAudioDeviceInfo("BSIZE")
  bsize = tonumber(bsize) or 0
  limit = bsize
  local masterTrack = reaper.GetMasterTrack(0)
  local automation = reaper.GetGlobalAutomationOverride()
  
  for i = 0, reaper.GetNumTracks() do
    local node = reaper.GetTrack(0, i) or masterTrack
    local bool, flags = reaper.GetTrackState(node)
    local trackAutomation = reaper.GetTrackAutomationMode(node)
    tracks[i+1] = node
    if automation > 1 and automation < 6 or 
      trackAutomation > 1 and trackAutomation < 6 or
      bool and
      (flags & 64) ~= 0 and
      (flags & 128) ~= 0 or
      (flags & 256) ~= 0 then
      inputTracks[#inputTracks+1] = node
    end
  end
  
  for i = 1, #inputTracks > 0 and #tracks or 0 do
    local node = tracks[i]
    network[node] = network[node] or {}
    local neighbour = reaper.GetParentTrack(node)
    local link = reaper.GetMediaTrackInfo_Value(node, "B_MAINSEND")
    if link == 1 and not neighbour and node ~= masterTrack then
      network[node][masterTrack] = true
    end
    if link == 1 and neighbour then
      network[node][neighbour] = true
    end
    
    --"reverse neighbourhood"
    for j = 0, reaper.GetTrackNumSends(node, -1) -1 do --zero index -1
      local neighbour = node
      local muteState = 
        reaper.GetTrackSendInfo_Value(neighbour, -1, j, "B_MUTE")
      local node = 
        reaper.GetTrackSendInfo_Value(neighbour, -1, j, "P_SRCTRACK")
      if muteState ~= 1 then
        network[node] = network[node] or {}
        network[node][neighbour] = true
      end
    end
  end
  
  return
end

local function GetSetState(isSet)
  local isSet = isSet
  local extName = "ak5k"
  local key = "llm"
  local keySafe = "llm_safe"
  local retval
  local extState
  local n = 0

  if not isSet
    --and stateCount ~= stateCount0 
    then
    local trackFXsDisabled = ClearTable(state.trackFXsDisabled)
    retval, extState = reaper.GetProjExtState(0, extName, key)
    if extState:len() > 0 then
      for s in extState:gmatch("[^;]+") do
        local k, v = string.match(s, "(.+),(%d+)")
        trackFXsDisabled[k] = tonumber(v)
      end
    end
    
    local trackFXsSafe = ClearTable(state.trackFXsSafe)
    retval, extState = reaper.GetProjExtState(0, extName, keySafe)
    if extState:len() > 0 then
      for s in extState:gmatch("[^;]+") do
        trackFXsSafe[s] = true
      end
    end
  end
  
  if isSet then
    local concat = table.concat
    local temp = ClearTable(state.temp)
    
    for k, v in pairs(state.trackFXsDisabled) do
      temp[#temp+1] = k
      temp[#temp+1] = ","
      temp[#temp+1] = v
      temp[#temp+1] = ";"
    end
    retval = reaper.SetProjExtState(0, extName, key, concat(temp))
    
    temp = ClearTable(temp)
    for k, _ in pairs(state.trackFXsSafe) do
      temp[#temp+1] = k
      temp[#temp+1] = ";"
    end
    retval = reaper.SetProjExtState(0, extName, keySafe, concat(temp))
    for i = #temp, 1, -1 do
      temp[i] = nil
    end
    collectgarbage()
  end
  
  return
end

local function GetLatency(node, currentLatency)
  local trackFXsToDisable = state.trackFXsToDisable
  local trackFXsDisabled = state.trackFXsDisabled
  local trackFXsSafe = state.trackFXsSafe
  local track = node
  local currentLatency = currentLatency or 0
  local latency = 0
  
  --ignore first instrument
  local instrument = reaper.TrackFX_GetInstrument(node)
  
  for i = 0, reaper.TrackFX_GetCount(track) -1 do
    local guid = reaper.TrackFX_GetFXGUID(track, i)
    local isEnabled = reaper.TrackFX_GetEnabled(track, i)
    local fxLatency = 
      tonumber(
        select(2, 
          reaper.TrackFX_GetNamedConfigParm(track, i, "pdc")))
    
    --check if already handled
    local previouslyDisabled = false
    if trackFXsDisabled[guid] then
      previouslyDisabled = true
    end
    
    --safe
    --always safe first instrument
    local isSafe = false
    if isEnabled and previouslyDisabled or i == instrument then
      trackFXsSafe[guid] = true
      isSafe = true
    elseif trackFXsSafe[guid] then
      isSafe = true
    end
    
    --unsafe
    --'rotate back to llm world'
    if isSafe and not isEnabled then
      trackFXsSafe[guid] = nil
      isSafe = false
      previouslyDisabled = true
    end
    
    --manually disabled
    if not isEnabled and not previouslyDisabled then
      fxLatency = 0
    end
    
    --check latency
    if fxLatency > 0 then
      local ceil = math.ceil
      latency = latency + fxLatency
      if currentLatency + ceil(latency / bsize) * bsize > limit and 
        not isSafe then
        latency = latency - fxLatency
        trackFXsToDisable[guid] = fxLatency
      end
    end
  end
  
  if latency > 0 then
    currentLatency = 
      currentLatency + ((latency // bsize) + 1) * bsize
  end
  
  return currentLatency
end


--signalchain as directed network
--recursive dft algoriddim with backtracking
local function TraverseNetwork(node, currentLatency)
  local node = node
  local network = state.network
  local currentLatency = currentLatency
  
  local route = state.route
  if not currentLatency then
    route = ClearTable(state.route)
  end
  
  local currentLatency = currentLatency or 0
  
  currentLatency = GetLatency(node, currentLatency)
  
  route[node] = true
  
  if not next(network[node]) then
    return
  else
    for neighbour in pairs(network[node]) do
      if not route[neighbour] then
        TraverseNetwork(neighbour, currentLatency)
      end
    end
    route[node] = nil
    return
  end
end

--local stack2 = {}
local function TraverseNetworkX(node)
  local G = state.network
  local v = node
  S = ClearTable(stack2)
  
  S[#S+1] = {
    G[v],
    nil,
    GetLatency(v)
  }
  
  while #S > 0 do
    local w = next(S[#S][1], S[#S][2])
    if w and not S[w] then
      S[#S][2] = w
      S[w] = true
      S[#S+1] = {}
      S[#S][1] = G[w]
      S[#S][2] = nil
      S[#S][3] = S[#S][3] or GetLatency(w, S[#S-1][3])
    else
      S[#S][1], S[#S][1], S[#S][1] = nil, nil, nil 
      S[#S] = nil
    end
  end
  
  return
end

local function ProcessTrackFXs()
  local res = false
  local trackFXsToEnable = ClearTable(state.trackFXsToEnable)
  local trackFXs = state.trackFXs
  local trackFXsToDisable = state.trackFXsToDisable
  local trackFXsDisabled = state.trackFXsDisabled
  local trackFXsSafe = state.trackFXsSafe
  
  for k in pairs(trackFXsDisabled) do
    if not trackFXsToDisable[k] then
      trackFXsDisabled[k] = nil
      trackFXsToEnable[k] = true
    else
      trackFXsToDisable[k] = nil
    end
  end
  
  if next(trackFXsToEnable) or next(trackFXsToDisable) then
    res = true
    local preventCount = 0
    for _ in pairs(trackFXsToEnable) do
      preventCount = preventCount + 1
    end
    for _ in pairs(trackFXsToDisable) do
      preventCount = preventCount + 1
    end
    preventCount = preventCount + 4
    
    for i = 0, reaper.GetNumTracks(0) do
      local track = reaper.GetTrack(0, i) or reaper.GetMasterTrack(0)
      for j = 0, reaper.TrackFX_GetCount(track) -1 do
        local fxGUID = reaper.TrackFX_GetFXGUID(track, j)
        trackFXs[fxGUID] = trackFXs[fxGUID] or {true, true}
        trackFXs[fxGUID][1] = track
        trackFXs[fxGUID][2] = j
      end
    end
    
    for k in pairs(trackFXsSafe) do
      if not trackFXs[k] then
        trackFXsSafe[k] = nil
      end
    end
    
    reaper.PreventUIRefresh(preventCount)
    reaper.Undo_BeginBlock()
    
    local automation = reaper.GetGlobalAutomationOverride()
    reaper.SetGlobalAutomationOverride(6)
    
    for k in pairs(trackFXsToEnable) do
      if trackFXs[k] then
        reaper.TrackFX_SetEnabled(trackFXs[k][1], trackFXs[k][2], true)        
      end
    end
  
    for k, v in pairs(trackFXsToDisable) do
      reaper.TrackFX_SetEnabled(trackFXs[k][1], trackFXs[k][2], false)
      trackFXsDisabled[k] = v
    end
    
    reaper.SetGlobalAutomationOverride(automation)
    
    reaper.Undo_EndBlock("Low latency monitoring", -1)
    reaper.PreventUIRefresh(-preventCount)
  end
  return res
end

--count, count0, count_time = 0, 0, 0
--time0, time1, time_max = 0, 0, 0
--collectgarbage("stop")

local stateCount0, stateCount = 0, 0
local function main(exit)
  
  --time0 = reaper.time_precise()
  
  stateCount0 = stateCount
  stateCount = 
    reaper.GetProjectStateChangeCount(0) +
    (reaper.GetGlobalAutomationOverride() + 1)
  
  
  UpdateState()
  GetSetState()
  
  if bsize > 0 then
    local inputTracks = state.inputTracks
    for i = 1, #inputTracks do
      TraverseNetwork(inputTracks[i])
    end
  end
  
  if exit then
    local trackFXsToDisable = state.trackFXsToDisable
    trackFXsToDisable = ClearTable(trackFXsToDisable)
  end
  
  local isSet = ProcessTrackFXs()
  
  if isSet then 
    GetSetState(isSet)
  end
  
  --[[
  time1 = reaper.time_precise() - time0
  time_max = time_max or 0
  if time1 > time_max then
    time_max = time1
  end
  
  count0 = count
  count = collectgarbage("count") * 1024 // 1024
  
  if count < count0 then
    count_time = time1
  end
  ]]--
  
  reaper.defer(main)
end

local function ToggleCommandState(state)
  local _, _, sec, cmd = reaper.get_action_context()
  reaper.SetToggleCommandState(sec, cmd, state)
  reaper.RefreshToolbar2(sec, cmd)
end

local function exit()
  local exit = true
  main(exit)
  ToggleCommandState(0)
end

ToggleCommandState(1)

reaper.defer(main)

reaper.atexit(exit)

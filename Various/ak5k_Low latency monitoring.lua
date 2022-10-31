-- @description Low latency monitoring
-- @author ak5k
-- @version 2.2.1
-- @changelog Detects if ReaLlm extension is installed and exits to prevent conflict.
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

-- @description Low latency monitoring
-- @author ak5k
-- @version 2.2.0
-- @changelog
--   Improved path recursion.
--
--   Simple internalized table object memory management.
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

local stack = {}
local inputTracks = nil
local network = nil
local route = nil
local temp = nil
local tracks = nil
local trackFXs = nil
local trackFXsToEnable = nil
local trackFXsToDisable = nil
local trackFXsDisabled = nil
local trackFXsSafe = nil

if reaper.NamedCommandLookup("_AK5K_REALLM") ~= 0 then
 reaper.MB(
    "ReaLlm extension detected.\n" ..
    "Use ReaLlm instead of this script.\n" ..
    "Exiting...\n",
    "ak5k: Low latency monitoring",0)
  return
end

local function NewTable()
  local next = next
  local setmetatable = setmetatable
  local s = stack
  local t
  if next(s) then
    t = s[#s]
    s[#s] = nil
  else
    t = {}
      setmetatable(
        t, {
          __gc = function(t)
            local pairs = pairs
            for k in pairs(t) do
              t[k] = nil
            end
            s[#s+1] = t
          end
        }
      )
    end
  return t
end

local function UpdateState()
  inputTracks = NewTable()
  network = NewTable() 
  tracks = NewTable()
  trackFXs = NewTable()
  
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
    network[node] = network[node] or NewTable()
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
        network[node] = network[node] or NewTable()
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
   trackFXsDisabled = NewTable() --ClearTable(state.trackFXsDisabled)
    retval, extState = reaper.GetProjExtState(0, extName, key)
    if extState:len() > 0 then
      for s in extState:gmatch("[^;]+") do
        local k, v = string.match(s, "(.+),(%d+)")
        trackFXsDisabled[k] = tonumber(v)
      end
    end
    
    trackFXsSafe = NewTable() --ClearTable(state.trackFXsSafe)
    retval, extState = reaper.GetProjExtState(0, extName, keySafe)
    if extState:len() > 0 then
      for s in extState:gmatch("[^;]+") do
        trackFXsSafe[s] = true
      end
    end
  end
  
  if isSet then
    local concat = table.concat
    local temp = NewTable() --ClearTable(state.temp)
    
    for k, v in pairs(trackFXsDisabled) do
      temp[#temp+1] = k
      temp[#temp+1] = ","
      temp[#temp+1] = v
      temp[#temp+1] = ";"
    end
    retval = reaper.SetProjExtState(0, extName, key, concat(temp))
    
    temp = NewTable() --ClearTable(temp)
    for k, _ in pairs(trackFXsSafe) do
      temp[#temp+1] = k
      temp[#temp+1] = ";"
    end
    retval = reaper.SetProjExtState(0, extName, keySafe, concat(temp))
    for i = #temp, 1, -1 do
      temp[i] = nil
    end
    --collectgarbage()
  end
  
  return
end

local function GetLatency(node, currentLatency)
  trackFXsToDisable = trackFXsToDisable or NewTable()
  trackFXsDisabled = trackFXsDisabled or NewTable()
  trackFXsSafe = trackFXsSafe or NewTable()
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
local function TraverseNetwork(node, currentLatency, route)
  local node = node
  local currentLatency = currentLatency or 0
  local route = route or NewTable()
  local network = network
  
  currentLatency = GetLatency(node, currentLatency)
  
  if not next(network[node]) then
    return
  else
    for neighbour in pairs(network[node]) do
      if not route[neighbour] then
        route[node] = true
        TraverseNetwork(neighbour, currentLatency, route)
        route[node] = nil
      end
    end
    
    return
  end
end

local function ProcessTrackFXs()
  local res = false
  local trackFXsToEnable = NewTable()--ClearTable(state.trackFXsToEnable)
  local trackFXs = trackFXs or NewTable()
  local trackFXsToDisable = trackFXsToDisable or NewTable()
  local trackFXsDisabled = trackFXsDisabled or NewTable()
  local trackFXsSafe = trackFXsSafe or NewTable()
  
  for k in pairs(trackFXsDisabled) do
    if not trackFXsToDisable[k] then
      trackFXsDisabled[k] = nil
      trackFXsToEnable[k] = true
    else
      trackFXsToDisable[k] = nil
    end
  end
  
  if next(trackFXsToEnable) or 
    next(trackFXsToDisable) then
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

local stateCount0, stateCount = 0, 0
collectgarbage("stop")
local function main(exit)
  --[[
  size = #stack
  size_max = size_max or 0
  if size > size_max then
    size_max = size
  end
  time0 = reaper.time_precise()
  ]]--
  
  stateCount0 = stateCount
  stateCount = 
    reaper.GetProjectStateChangeCount(0) +
    (reaper.GetGlobalAutomationOverride() + 1)
  
  if stateCount ~= stateCount0 then
  
  UpdateState()
  GetSetState()
  
  if bsize > 0 then
    --local inputTracks = inputTracks
    for i = 1, #inputTracks do
      TraverseNetwork(inputTracks[i])
    end
  end
  
  
  if exit then
    --local trackFXsToDisable = state.trackFXsToDisable
    trackFXsToDisable = NewTable() --ClearTable(trackFXsToDisable)
  end
  
  local isSet = ProcessTrackFXs()
  
  if isSet then 
    GetSetState(isSet)
  end
  
  collectgarbage("collect")
  end
  
  --[[
  time1 = reaper.time_precise() - time0
  time_max = time_max or 0
  if time1 > time_max and time1 < 0.005 then
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



-- @description Low latency monitoring
-- @author ak5k
-- @version 0.2.1
-- @changelog
--   New streamlined and strongly opinionated version.
--
--   Same core functionality as before but with no user setting 'hassle'.
--
--   Assumes Per-chain PDC compensation mode (default in REAPER version > 6.19). Works with other modes too in a kind of 'will not break things' way.
--
--   Plugins can now be manually enabled/bypassed while Low latency monitoring script is running, and manual user choices are persistent. This makes previous including/excluding plugins or tracks with tags obsolete.
--
--   Hard limit is no longer available.  No separate PDC or individual plugin limit settings. PDC limit is fixed to one audio driver block/buffer. This should leave enough 'PDC headroom' to begin with. It's now just easier and faster to 'manually override' plugins anyway. 
--
--   Simpler and, hopefully, more robust.
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

local collectgarbage = collectgarbage
local next = next
local pairs = pairs
local reaper = reaper
local string = string
local tonumber = tonumber
local type = type
-- reaper.ShowConsoleMsg("")

local limit = 0 --spls
local bsize = 0

local graph = {}
local inputTracks = {}
local trackFXs = {}
local trackFXsToDisable = {}
local trackFXsDisabled = {}
local trackFXsSafe = {}

local function GetSetState(isSet)
  local isSet = isSet
  local extname = "ak5k"
  local key = "llm"
  local keySafe = "llm_safe"
  local retval
  local state = ""
  local n = 0

  if not isSet then
    trackFXsDisabled = {}
    retval, state = reaper.GetProjExtState(0, extname, key)
    
    for s in string.gmatch(state, "[^;]+") do
      local k, v = string.match(s, "(.+),(%d+)")
      trackFXsDisabled[k] = tonumber(v)
    end
    
    trackFXsSafe = {}
    retval, state = reaper.GetProjExtState(0, extname, keySafe)

    for s in string.gmatch(state, "[^;]+") do
      trackFXsSafe[s] = true
    end
  end
  
  if isSet then
    state = ""
    for k, v in pairs(trackFXsDisabled) do
      state = state .. k .. "," .. v .. ";"
    end
    retval = reaper.SetProjExtState(0, extname, key, state)

    
    state = ""
    for k, _ in pairs(trackFXsSafe) do
      state = state .. k .. ";"
    end
    retval = reaper.SetProjExtState(0, extname, keySafe, state)
  end
  
  return
end

local function UpdateState()
  inputTracks = {}
  graph = {}
  trackFXs = {}
  trackFXsToDisable = {}
  local retval
  retval, bsize = reaper.GetAudioDeviceInfo("BSIZE")
  bsize = tonumber(bsize) or 0
  limit = bsize
  local masterTrack = reaper.GetMasterTrack(0)
  local automation = reaper.GetGlobalAutomationOverride()
  for i = 0, reaper.GetNumTracks() do
    local node = reaper.GetTrack(0, i) or masterTrack
    
    local bool, flags = reaper.GetTrackState(node)
    if automation > 1 or 
      reaper.GetTrackAutomationMode(node) > 1 or
      bool and
      (flags & 64) ~= 0 and
      (flags & 128) ~= 0 or
      (flags & 256) ~= 0 then
      inputTracks[#inputTracks+1] = node
    end
    
    graph[node] = graph[node] or {}
    local link = reaper.GetParentTrack(node)
    local linkActive = reaper.GetMediaTrackInfo_Value(node, "B_MAINSEND")
    if linkActive == 1 and not link and node ~= masterTrack then
      graph[node][masterTrack] = true
    end
    if linkActive == 1 and link then
      graph[node][link] = true
    end
    
    for j = 0, reaper.TrackFX_GetCount(node) -1 do
      local _, pdc = reaper.TrackFX_GetNamedConfigParm(node, j, "pdc")
      trackFXs[reaper.TrackFX_GetFXGUID(node, j)] =
        {
          node, 
          j, 
          tonumber(pdc)
        }
    end
    
    --"reverse"
    for j = 0, reaper.GetTrackNumSends(node, -1) -1 do --zero index -1
      local link = node
      local muteState = 
        reaper.GetTrackSendInfo_Value(link, -1, j, "B_MUTE")
      local node = 
        reaper.GetTrackSendInfo_Value(link, -1, j, "P_SRCTRACK")
      if muteState ~= 1 then
        graph[node] = graph[node] or {}
        graph[node][link] = true
      end
    end
    
  end
  return
end

local function FilterTrackFXChain(node, currentLatency)
  local trackFXs = trackFXs
  local trackFXsToDisable = trackFXsToDisable
  local trackFXsDisabled = trackFXsDisabled
  local track = node
  local currentLatency = currentLatency
  local latency = 0
  
  --ignore first instrument
  local instrument = reaper.TrackFX_GetInstrument(node)
  
  for i = 0, reaper.TrackFX_GetCount(node) -1 do
    local guid = reaper.TrackFX_GetFXGUID(node, i)
    local isEnabled = reaper.TrackFX_GetEnabled(node, i)
    
    local previouslyDisabled = false
    if trackFXsDisabled[guid] then
      previouslyDisabled = true
    end

    local fxLatency = trackFXs[guid][3]
    
    local isSafe = false
    if previouslyDisabled and isEnabled then
      trackFXsSafe[guid] = true
      isSafe = true
    elseif trackFXsSafe[guid] then
      isSafe = true
    end
    
    if isSafe and not isEnabled then
      trackFXsSafe[guid] = nil
      isSafe = false
    end
    
    --if not isEnabled and trackFXsDisabled[guid] then
    if not isEnabled and previouslyDisabled then
      fxLatency = trackFXsDisabled[guid]
    end
    
    if not isEnabled and not previouslyDisabled or 
      i == instrument then
      fxLatency = 0
    end
    
    if fxLatency > 0 then
      latency = latency + fxLatency
      if currentLatency + ((latency // bsize) + 1) * bsize > limit and 
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

local function ProcessTrackFXs()
  local res = false
  local trackFXsToEnable = {}
  local trackFXsToDisable = trackFXsToDisable
  local trackFXsDisabled = trackFXsDisabled
  
  for k in pairs(trackFXsDisabled) do
    if not trackFXsToDisable[k] then
      trackFXsDisabled[k] = nil
      trackFXsToEnable[k] = true
    else
      trackFXsToDisable[k] = nil
    end
    if not trackFXs[k] then
      trackFXsDisabled[k] = nil
    end
  end
  
  for k in pairs(trackFXsSafe) do
    if not trackFXs[k] then
      res = true
      trackFXsSafe[k] = nil
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

--signalchain as directed graph
local function SetTrackFXsToDisable(node, routes, route, currentLatency)
  local node = node
  local routes = routes or {}
  local route = route or {{},{}}
  local currentLatency = currentLatency or 0
  local graph = graph
  
  
  --signalchain is split
  --rotate current route to previous
  --create new empty route
  if next(graph[node], next(graph[node])) then
    route = {route[2], {}}
  end
  
  local currentRoute = route[2]
  local previousRoute = route[1]
  
  routes[currentRoute] = previousRoute
  currentRoute[#currentRoute+1] = node

  --detect feedback loop
  local backtrack = currentRoute
  while type(backtrack) == "table" and next(backtrack) do
  --while next(backtrack) do
    local lenght = #backtrack
    if backtrack == currentRoute then
      lenght = lenght - 1
    end
    for i = 1, lenght do
      if backtrack[i] == node then
        currentRoute[#currentRoute] = nil
        return
      end
    end
    backtrack = routes[backtrack]
  end
  
  currentLatency = FilterTrackFXChain(node, currentLatency)
  
  if not next(graph[node]) then
    return
  else
    --for link, _ in pairs(graph[node]) do
    for link in pairs(graph[node]) do
      routes = SetTrackFXsToDisable(link, routes, route, currentLatency)
    end
    return
  end
end

--count, count0, count_time = 0, 0, 0
collectgarbage("stop")
local function main()
  --time0 = reaper.time_precise()
  
  GetSetState()
  UpdateState()
  collectgarbage()
  
  if bsize > 0 then
    for i = 1, #inputTracks do
      SetTrackFXsToDisable(inputTracks[i])
    end
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
  count = collectgarbage("count")
  
  if count < count0 then
    count_time = time1
  end
  ]]--
  
  reaper.defer(main)
end

local function ToggleCommandState(state)
  local _, _, sec, cmd,_, _, _ = reaper.get_action_context()
  reaper.SetToggleCommandState(sec, cmd, state) -- Set ON
  reaper.RefreshToolbar2(sec, cmd)
end

local function AtExit()
  GetSetState()
  UpdateState()
  ProcessTrackFXs()
  GetSetState(true)
  ToggleCommandState(0)
  collectgarbage()
end

ToggleCommandState(1)

reaper.defer(main)

reaper.atexit(AtExit)

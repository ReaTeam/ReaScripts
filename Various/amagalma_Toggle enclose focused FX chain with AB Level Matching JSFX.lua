-- @description amagalma_Toggle enclose focused FX chain with AB Level Matching JSFX
-- @author amagalma
-- @version 1.0
-- @about
--   # Inserts or Removes TBProAudio's AB Level Matching JSFX at the start and at the end of the FX Chain in focus
--
--   - You must have TBProAudio's free AB_LM JSFX!
--   - http://www.tb-software.com/TBProAudio/ab_lmjsfx.html
-- @link http://forum.cockos.com/showthread.php?t=140268


-----------------------------------------------------------------------------
local reaper = reaper
local find = string.find
local insert = table.insert
local match = string.match
local concat = table.concat
local remove = table.remove

-----------------------------------------------------------------------------
local function GetInfo()
  local FXGUID, what, trackGUID
  local focus, track, item, fxid = reaper.GetFocusedFX()
  if focus == 1 then
    what = "track"
    if track == 0 then
      track = reaper.GetMasterTrack(0)
    else
      track = reaper.GetTrack(0, track-1)
    end
    trackGUID = reaper.guidToString(reaper.GetTrackGUID(track), "")
    FXGUID = reaper.guidToString(reaper.TrackFX_GetFXGUID(track, fxid), ""):gsub("-", "%%-")
  elseif focus == 2 then
    what = "item"
    item = reaper.GetMediaItem(0, item)
    track = reaper.GetMediaItemTrack(item)
    trackGUID = reaper.guidToString(reaper.GetTrackGUID(track), "")
    local take = reaper.GetMediaItemTake(item, fxid >> 16)
    FXGUID = reaper.guidToString(reaper.TakeFX_GetFXGUID(take, fxid & 0xFFFF), ""):gsub("-", "%%-")
  elseif focus == 0 then
    return nil
  end
  return FXGUID, track, what, trackGUID
end

-----------------------------------------------------------------------------
local function GetTrackChunk(track) -- eugen2777's workaround for chunks >4MB
  if not track then return end
  local fast_str, track_chunk
  fast_str = reaper.SNM_CreateFastString("")
  if reaper.SNM_GetSetObjectState(track, fast_str, false, false) then
    track_chunk = reaper.SNM_GetFastString(fast_str)
  end
  reaper.SNM_DeleteFastString(fast_str)  
  return track_chunk
end

-----------------------------------------------------------------------------
local function NoUndoPoint() end 

-----------------------------------------------------------------------------
local function InsertAB(FXGUID, track, what)
  if track then
    local source = {
    "BYPASS 0 0 0",
    '<JS AB_LM_src "-- AB Source --"',
    "  0.000000 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ",
    ">",
    "FLOATPOS 0 0 0 0",
    "FXID "..reaper.genGuid(),
    "WAK 0"
    }
    local t = {}
    local chunk = GetTrackChunk(track)
    for line in chunk:gmatch('[^\n]+') do       
      t[#t+1] = line
    end
    --local pivot
    if what == "track" then
      for i = 23, #t do
        if find(t[i], "BYPASS %d %d %d") then
          pivot = i
          break
        end
      end
      for i = 7, 1, -1 do
        insert(t, pivot, source[i])
      end
      for i = 24, 28 do
        if find(t[i], "SHOW %d") then
          local show = tostring(tonumber(match(t[i], "SHOW (%d)")) + 1)
          t[i] = "SHOW "..show
          break
        end
      end
    elseif what == "item" then
      for i = 23, #t do
        if find(t[i], FXGUID) then
          pivot = i
          break
        end
      end
      for i = pivot, 1, -1 do
        if find(t[i], "<TAKEFX") then
          pivot = i
          break
        end
      end
      for i = pivot, #t do
        if find(t[i], "BYPASS %d %d %d") then
          pivot = i
          break
        end
      end
      for i = #source, 1, -1 do
        insert(t, pivot, source[i])
      end
      for i = pivot, 1, -1 do
        if find(t[i], "SHOW %d") then
          local show = tostring(tonumber(match(t[i], "SHOW (%d)")) + 1)
          t[i] = "SHOW "..show
          break
        end
      end
    end
  -- Insert AB Control JSFX --
    pivot = nil
    local control = {
    "BYPASS 0 0 0",
    '<JS AB_LM_cntrl "-- AB Control --"',
    "  0.000000 0.000000 300.000000 1.000000 - - - - - 0.000000 - - - - - - - - - -141.000000 -141.000000 -144.000000 -3.000000 -144.000000 - - - - - -141.000000 -141.000000 -144.000000 -3.000000 -144.000000 - - - - - 0.000000 1.000000 0.000000 - 0.000000 0.000000 - - - - 0.000000 0.000000 - - - - - - - - - - - - - No preset",
    ">",
    'PRESETNAME "No preset"',
    "FLOATPOS 0 0 0 0",
    "FXID "..reaper.genGuid(),
    "WAK 0"
    }
    if what == "track" then
      for i = 23, #t do
        if find(t[i], "<ITEM") then
          pivot = i-1
          break
        else
          pivot = #t-1
        end
      end
    elseif what == "item" then
    for i = 1, #t do
    end
      for i = 23, #t do
        if find(t[i], FXGUID) then
          pivot = i
          break
        end
      end
      for i = pivot, #t do
        if find(t[i], "WAK %d") then
          if t[i+1] == ">" then
            pivot = i
            break
          end
        end
      end
    end
    for i = #control, 1, -1 do
      insert(t, pivot, control[i])
    end
    chunk = concat(t, "\n")
    reaper.SetTrackStateChunk(track, chunk, false)
  end
end

-----------------------------------------------------------------------------
local function RemoveAB()
  local focus, track, item, fxid = reaper.GetFocusedFX()
  if focus > 0 then
    if focus == 1 then
      if track == 0 then
        track = reaper.GetMasterTrack(0)
      else
        track = reaper.GetTrack(0, track-1)
      end
    elseif focus == 2 then
      item = reaper.GetMediaItem(0, item)
      track = reaper.GetMediaItemTrack(item)
    end
    local _, chunk
    local t = {}
    if focus == 1 then
      _, chunk = reaper.GetTrackStateChunk(track, "", false)
    elseif focus == 2 then
      _, chunk = reaper.GetItemStateChunk(item, "", false)
    end
    for line in chunk:gmatch('[^\n]+') do       
      t[#t+1] = line
    end
    local FXStartLine, FXEndLine
    local change = 0
    -- Remove JS AB_LM_src plugin
    for i = 1, #t do
      if find(t[i], "<JS AB_LM_src.*") then
        FXStartLine = i-1
        break
      end
    end
    if FXStartLine then 
      for i = FXStartLine+1, #t do
        if find(t[i], "WAK %d") then
          FXEndLine = i
          break
        end
      end
      for i = 1, FXEndLine-FXStartLine+1 do
        remove(t, FXStartLine)
      end
      change = 1
    end
    -- Remove JS AB_LM_cntrl plugin --
    for i = 1, #t do
      if find(t[i], "<JS AB_LM_cntrl.*") then
        FXStartLine = i-1
        break
      end
    end
    if FXStartLine then 
      for i = FXStartLine+1, #t do
        if find(t[i], "WAK %d") then
          FXEndLine = i
          break
        end
      end
      for i = 1, (FXEndLine-FXStartLine+1) do
        remove(t, FXStartLine)
      end
      change = 1
    end
    -- Set chunk
    if change == 1 then
      reaper.Undo_BeginBlock()
      chunk = concat(t, "\n")
      if focus == 1 then
        reaper.SetTrackStateChunk(track, chunk, false)
      elseif focus == 2 then
        reaper.SetItemStateChunk(item, chunk, false)
      end
      reaper.Undo_EndBlock("Remove AB plugins from focused FX Chain", -1)
    else
      reaper.defer(NoUndoPoint)
    end
  else
    reaper.defer(NoUndoPoint)
  end
end
-- Main function ---------------------------------------------------------
local FXGUID, track, what, trackGUID = GetInfo()
if track and trackGUID then
  local ok, value = reaper.GetProjExtState(0, "AB JSFX Toggle Chain", trackGUID)
  if ok and value == "1" then
    RemoveAB()
    reaper.SetProjExtState(0, "AB JSFX Toggle Chain", trackGUID, "0")
  else
    reaper.Undo_BeginBlock()
    InsertAB(FXGUID, track, what)
    reaper.SetProjExtState(0, "AB JSFX Toggle Chain", trackGUID, "1")
    reaper.Undo_EndBlock("Enclose focused FX Chain with AB JSFX", -1)
  end
end

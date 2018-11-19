-- @description amagalma_Toggle insert-remove AB_LM Level Matching VST to focused FX
-- @author amagalma
-- @version 1.1
-- @about
--   # Inserts or Removes TBProAudio's AB_LM Level Matching VST2 or VST3 before and after focused FX
--
--   - You must have TBProAudio's AB_LM VST
-- @link http://www.tb-software.com/TBProAudio/ab_lm.html

--[[
  @changelog
    -- Smart undo creation
--]]

------------------------------------------------------------------------------------------------

local reaper = reaper
local find = string.find
local insert = table.insert
local match = string.match
local concat = table.concat
local remove = table.remove

------------------------------------------------------------------------------------------------
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
  return FXGUID, track, what, trackGUID, fxid
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

------------------------------------------------------------------------------------------------
local function NoUndoPoint() end 

------------------------------------------------------------------------------------------------
-- Check if AB_LM .dll or .vst3 exists in reaper-vstplugins.ini
local vst_ini, vst = reaper.GetResourcePath() .. "\\reaper-vstplugins.ini"
local file = io.open (vst_ini)
local t = {}
for line in file:lines() do
  t[#t+1] = line 
end
io.close(file)
for i = 1, #t do
  if string.match(t[i], "AB_LM.dll") then
    vst = 2
    break
  elseif string.match(t[i], "AB_LM.vst3") then
    vst = 3
    break
  end
end
if not vst then
  reaper.MB( "No AB_LM VST2 or VST3 has been found on your system.", "Can't run the action!", 0 )
end

------------------------------------------------------------------------------------------------
local function InsertAB(FXGUID, track, what, fxID)
  if FXGUID and track then
    local source 
    if vst == 2 then
      source = {
      "BYPASS 0 0 0",
      '<VST "VST: AB_LM (TBProAudio)" AB_LM.dll 0 "-- AB_LM Send --" 1413632055',
      "N1BCVO9e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAAeAAAAAAAAAAAABAA",
      "776t3g3wrd4AAAAAAACAOwAAAACamRk/WAIePwAAgD8AACA/AAAAPwAAgD8AAAA/AAAAAAAAAD8AAAA/AAAAAAAAAD8AAAA/AAAAAAAAAD8AAAA/AAAAAAAAAD8AAAA/",
      "AAAAAAAAAD8AAAA/AAAAAAAAgD8AAAAA",
      "RGVmYXVsdABEZWZhdWx0ABAAAAA=",
      ">",
      "PRESETNAME Default",
      "FLOATPOS 0 0 0 0",
      "FXID "..reaper.genGuid(),
      "WAK 0"
      }
    elseif vst == 3 then
      source = {
      "BYPASS 0 0 0",
      '<VST "VST: AB_LM (TBProAudio)" AB_LM.dll 0 "-- AB_LM Send --" 1413632055',
      "N1BCVO9e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAAeAAAAAAAAAAAABAA",
      "776t3g3wrd4AAAAAAACAOwAAAACamRk/WAIePwAAgD8AACA/AAAAPwAAgD8AAAA/AAAAAAAAAD8AAAA/AAAAAAAAAD8AAAA/AAAAAAAAAD8AAAA/AAAAAAAAAD8AAAA/",
      "AAAAAAAAAD8AAAA/AAAAAAAAgD8AAAAA",
      "RGVmYXVsdABEZWZhdWx0ABAAAAA=",
      ">",
      "PRESETNAME Default",
      "FLOATPOS 0 0 0 0",
      "FXID "..reaper.genGuid(),
      "WAK 0"
      }
    end
    local t = {}
    local chunk = GetTrackChunk(track)
    for line in chunk:gmatch('[^\n]+') do       
      t[#t+1] = line
    end
    local FXEndLine, pivot
    for i = 30, #t do
      if find(t[i], FXGUID) then
        FXEndLine = i
        break
      end
    end 
    for i = FXEndLine-4, 1, -1 do
      if find(t[i], "BYPASS %d %d %d") then
        pivot = i
        break
      end
    end
    for i = #source, 1, -1 do
      insert(t, pivot, source[i])
    end
    if what == "track" then -- TRACK FX ------------------------------------------------------
      for i = 24, 28 do
        if find(t[i], "SHOW %d") then
          local show = tostring(tonumber(match(t[i], "SHOW (%d)")) + 1)
          t[i] = "SHOW "..show
          break
        end
      end
    elseif what == "item" then -- ITEM FX ------------------------------------------------------
      for i = FXEndLine, 1, -1 do
        if find(t[i], "SHOW %d") then
          local show = tostring(tonumber(match(t[i], "SHOW (%d)")) + 1)
          t[i] = "SHOW "..show
          break
        end
      end
    end--]]
  -- Insert AB Receive VST3 --
    local control
    if vst == 2 then
    control = {
    "BYPASS 0 0 0",
    '<VST "VST: AB_LM (TBProAudio)" AB_LM.dll 0 "-- AB_LM Receive --" 1413632055',
    "N1BCVO9e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAAeAAAAAAAAAAAABAA",
    "776t3g3wrd4AAIA/AACAOwAAAACamRk/WAIePwAAgD8AACA/AAAAPwAAgD8AAAA/AAAAAAAAAD8AAAA/AAAAAAAAAD8AAAA/AAAAAAAAAD8AAAA/AAAAAAAAAD8AAAA/",
    "AAAAAAAAAD8AAAA/AAAAAAAAgD8AAAAA",
    "RGVmYXVsdABEZWZhdWx0ABAAAAA=",
    ">",
    "PRESETNAME Default",
    "FLOAT 100 100 440 671",
    "FXID "..reaper.genGuid(),
    "WAK 0"
    }
  elseif vst == 3 then
    control = {
    "BYPASS 0 0 0",
    '<VST "-- AB_LM Receive --" AB_LM.vst3 0 "" 157181286{F2AEE70D00DE4F4E5442504154425037}',
    "ZmVeCe9e7f4CAAAAAQAAAAAAAAACAAAAAAAAAAIAAAABAAAAAAAAAAIAAAAAAAAAdAAAAAAAAAAAABAA",
    "776t3g3wrd4AAAAAAAAAAAAAgD8AAIA7AAAAAAAAgD9YAh4/AACAPwAAMD8AAAA/AACAPwAAAD8AAAAAAAAAPwAAAD8AAAAAAAAAPwAAAD8AAAAAAAAAPwAAAD8AAAAA",
    "AAAAPwAAAD8AAAAAAAAAPwAAAD8=",
    "RGVmYXVsdABEZWZhdWx0ABAAAAA=",
    ">",
    "PRESETNAME Default",
    "FLOAT 100 100 440 671",
    "FXID "..reaper.genGuid(),
    "WAK 0"
    }
  end
    FXEndLine = FXEndLine + 6
    for i = FXEndLine+1, #t do
      if find(t[i], "WAK %d") then
        pivot = i + 1
        break
      end
    end
    for i = #control, 1, -1 do
      insert(t, pivot, control[i])
    end
    chunk = concat(t, "\n")
    reaper.SetTrackStateChunk(track, chunk, false)
    reaper.TrackFX_Show( track, fxID, 3 )
  end
end

------------------------------------------------------------------------------------------------
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
    -- Remove VST3 AB_LM send plugin
    for i = 1, #t do
      if find(t[i], '-- AB_LM Send --') then
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
    -- Remove VST3 AB_LM receive plugin --
    for i = 1, #t do
      if find(t[i], '-- AB_LM Receive --') then
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
      reaper.Undo_EndBlock("Remove AB_LM VST3 plugins from focused FX chain", -1)
    else
      reaper.defer(NoUndoPoint)
    end
  else
    reaper.defer(NoUndoPoint)
  end
end

-- Main function -------------------------------------------------------------------------------
local FXGUID, track, what, trackGUID, fxID= GetInfo()
if track and trackGUID then
  local ok, value = reaper.GetProjExtState(0, "AB VST3 Toggle", trackGUID)
  if ok and value == "1" then
    RemoveAB()
    reaper.SetProjExtState(0, "AB VST3 Toggle", trackGUID, "0")
  else
    reaper.Undo_BeginBlock()
    InsertAB(FXGUID, track, what, fxID+2)
    reaper.SetProjExtState(0, "AB VST3 Toggle", trackGUID, "1")
    reaper.Undo_EndBlock("Insert AB_LM VST3 plugins to focused FX", -1)
  end
else
  reaper.defer(NoUndoPoint)
end

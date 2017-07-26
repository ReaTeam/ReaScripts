-- @description amagalma_Insert AB Level Matching JSFX to focused FX
-- @author amagalma
-- @version 1.0
-- @about
--   # Inserts TBProAudio's AB Level Matching JSFX before and after focused FX
--
--   - You must have TBProAudio's free AB_LM JSFX!
--   - http://www.tb-software.com/TBProAudio/ab_lmjsfx.html

local reaper = reaper

local function GetFXGUID()
  local FXGUID, what
  local focus, track, item, fxid = reaper.GetFocusedFX()
  if focus == 1 then
    what = "track"
    if track == 0 then
      track = reaper.GetMasterTrack(0)
    else
      track = reaper.GetTrack(0, track-1)
    end
    FXGUID = reaper.guidToString(reaper.TrackFX_GetFXGUID(track, fxid), ""):gsub("-", "%%-")
  elseif focus == 2 then
    what = "item"
    item = reaper.GetMediaItem(0, item)
    track = reaper.GetMediaItemTrack(item)
    local take = reaper.GetMediaItemTake(item, fxid >> 16)
    FXGUID = reaper.guidToString(reaper.TakeFX_GetFXGUID(take, fxid & 0xFFFF), ""):gsub("-", "%%-")
  elseif focus == 0 then
    return nil
  end
  return FXGUID, track, what
end


local function InsertSRC(FXGUID, track, what)
  if FXGUID and track then
    local source = {
    "BYPASS 0 0",
    "FXID_NEXT "..reaper.genGuid(),
    '<JS AB_LM_src "-- AB Source --"',
    "  0.000000 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ",
    ">",
    "WAK 0"
    }
    local t = {}
    local _, chunk = reaper.GetTrackStateChunk(track, "", false)
    for line in chunk:gmatch('[^\n]+') do       
      t[#t+1] = line
    end
    local FXEndLine, pivot
    for i = 30, #t do
      if string.find(t[i], FXGUID) then
        FXEndLine = i
        break
      end
    end 
    for i = FXEndLine-4, 1, -1 do
      if string.find(t[i], "BYPASS %d %d %d") then
        pivot = i
        break
      end
    end
    for i = 6, 1, -1 do
      table.insert(t, pivot, source[i])
    end
    if what == "track" then
      for i = 24, 28 do
        if string.find(t[i], "SHOW %d") then
          local show = tostring(tonumber(string.match(t[i], "SHOW (%d)")) + 1)
          t[i] = "SHOW "..show
          break
        end
      end
    elseif what == "item" then
      for i = FXEndLine, 1, -1 do
        if string.find(t[i], "SHOW %d") then
          local show = tostring(tonumber(string.match(t[i], "SHOW (%d)")) + 1)
          t[i] = "SHOW "..show
          break
        end
      end
    end
    chunk = table.concat(t, "\n")
    reaper.SetTrackStateChunk(track, chunk, false)
  end
end


local function InsertCNTRL(FXGUID, track)
  if FXGUID and track then
    local control = {
    "BYPASS 0 0",
    "FXID_NEXT "..reaper.genGuid(),
    '<JS AB_LM_cntrl "-- AB Control --"',
    "  0.000000 0.000000 300.000000 1.000000 - - - - - 0.000000 - - - - - - - - - -141.000000 -141.000000 -144.000000 -3.000000 -144.000000 - - - - - -141.000000 -141.000000 -144.000000 -3.000000 -144.000000 - - - - - 0.000000 1.000000 0.000000 - 0.000000 0.000000 - - - - 0.000000 0.000000 - - - - - - - - - - - - - No preset",
    ">",
    'PRESETNAME "No preset"',
    "WAK 0"
    }
    local t = {}
    local _, chunk = reaper.GetTrackStateChunk(track, "", false)
    for line in chunk:gmatch('[^\n]+') do       
      t[#t+1] = line
    end
    local FXEndLine, pivot
    for i = 30, #t do
      if string.find(t[i], FXGUID) then
        FXEndLine = i
        break
      end 
    end
    for i = FXEndLine+1, #t do
      if string.find(t[i], "WAK %d") then
        pivot = i + 1
        break
      end
    end
    for i = 7, 1, -1 do
      table.insert(t, pivot, control[i])
    end
    chunk = table.concat(t, "\n")
    reaper.SetTrackStateChunk(track, chunk, false)
  end
end


local FXGUID, track, what = GetFXGUID()
if track then
  reaper.Undo_BeginBlock()
  InsertSRC(FXGUID, track, what)
  InsertCNTRL(FXGUID, track, what)
  reaper.Undo_EndBlock("Insert AB plugins to focused FX", -1)
end

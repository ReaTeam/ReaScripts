-- @description amagalma_Remove AB Level Matching JSFX from focused FX chain
-- @author amagalma
-- @version 1.0
-- @about
--   # Removes TBProAudio's AB Level Matching JSFX from focused FX chain
--
--   - You must have TBProAudio's free AB_LM JSFX!
--   - http://www.tb-software.com/TBProAudio/ab_lmjsfx.html
--   - To be used alongside my "amagalma_Insert AB Level Matching JSFX to focused FX" action

local reaper = reaper

local function NoUndoPoint() end 

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
      if string.find(t[i], "<JS AB_LM_src.*") then
        FXStartLine = i-1
        break
      end
    end
    if FXStartLine then 
      for i = FXStartLine+1, #t do
        if string.find(t[i], "WAK %d") then
          FXEndLine = i
          break
        end
      end
      for i = 1, FXEndLine-FXStartLine+1 do
        table.remove(t, FXStartLine)
      end
      change = 1
    end
    -- Remove JS AB_LM_cntrl plugin
    for i = 1, #t do
      if string.find(t[i], "<JS AB_LM_cntrl.*") then
        FXStartLine = i-1
        break
      end
    end
    if FXStartLine then 
      for i = FXStartLine+1, #t do
        if string.find(t[i], "WAK %d") then
          FXEndLine = i
          break
        end
      end
      for i = 1, (FXEndLine-FXStartLine+1) do
        table.remove(t, FXStartLine)
      end
      change = 1
    end
    -- Set chunk
    if change == 1 then
      reaper.Undo_BeginBlock()
      chunk = table.concat(t, "\n")
      if focus == 1 then
        reaper.SetTrackStateChunk(track, chunk, false)
      elseif focus == 2 then
        reaper.SetItemStateChunk(item, chunk, false)
      end
      reaper.Undo_EndBlock("Remove AB plugins from focused FX chain", -1)
    else
      reaper.defer(NoUndoPoint)
    end
  else
    reaper.defer(NoUndoPoint)
  end
end

RemoveAB()

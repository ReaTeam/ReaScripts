-- @description amagalma_Toggle enclose focused FX chain with AB_LM Level Matching VST/JSFX
-- @author amagalma
-- @version 1.27
-- @about
--   # Inserts or Removes TBProAudio's AB_LM Level Matching VST/JSFX enclosing the focused FX chain
--   - Automatically checks if AB_LM VST2, VST3 or JSFX are present in your system
--   - Ability to set in the script the prefered format of AB_LM (VST2, VST3 or JSFX)
--   - Smart undo point creation
-- @link http://www.tb-software.com/TBProAudio/ab_lm.html
-- @changelog
--    # hopefully, first-time-run error-checking should be fixed now for x64 platforms

------------------------------------------------------------------------------------------------
local reaper = reaper

--==============================================================================
local pref = 1 -- SET HERE YOUR PREFERENCE (1 = JSFX, 2 = VST2, 3 = VST3      ==
local lite = 0 -- SET TO 1 IF YOU PREFER THE LITE VERSION OF THE JSFX CONTROL ==
--==============================================================================

------------------------------------------------------------------------------------------------

local not_firsttime = reaper.HasExtState( "AB_LM Toggle", "format" )
if not not_firsttime then
  local separ = string.match(reaper.GetOS(), "Win") and "\\" or "/"
  local path = reaper.GetResourcePath()
  -- first time running the script, do the checks
  -- Check Reaper version
  if tonumber(reaper.GetAppVersion():match("%d+.%d+")) < 5.965 then
    reaper.MB( "Please, update to Reaper v5.965 or newer.", "Cannot run script!", 0 )
    reaper.defer(function() end)
    return
  end
  -- Check if js_ReaScriptAPI extension is installed
    local i = 0
    local file, exists = true, false
    while file do
      file = reaper.EnumerateFiles( path .. separ .. "UserPlugins", i )
      if file:match"reaper_js_ReaScriptAPI" then
        exists = true
        break
      end
      i = i + 1
    end
    if exists then
      local js_vers = reaper.JS_ReaScriptAPI_Version()
      if js_vers < 0.962 then
        reaper.MB( "You need js_ReaScriptAPI extension v0.962 or newer.", "Cannot run script!", 0 )
        reaper.defer(function() end)
        return
      end
    else
      reaper.MB( "You need to install js_ReaScriptAPI extension from ReaPack.", "Cannot run script!", 0 )
      reaper.defer(function() end)
      return
    end
  -- Check if AB_LM .dll or .vst3 or jsfx exist in your system
  local jsfx, vst2, vst3 = false, false, false
  local OS, architecture = string.match(reaper.GetOS(), "(%a+)(%d?%d?)")
  local separ = OS == "Win" and "\\" or "/"
  local vst_ini
  if architecture == "32" then
    vst_ini = reaper.GetResourcePath() .. separ .."reaper-vstplugins.ini"
  elseif architecture == "64" then
    vst_ini = reaper.GetResourcePath() .. separ .."reaper-vstplugins64.ini"
  end
  local jsfx_ini = reaper.GetResourcePath() .. separ .. "reaper-jsfx.ini"
  if architecture ~= "" then
    -- check for VST2/3 presence, if not Linux
    local file = io.open (vst_ini)
    if file then
      for line in file:lines() do
        if line:match("AB_LM[_x64]*.dll") then
          vst2 = 2
        elseif line:match("AB_LM[_x64]*.vst3") then
          vst3 = 3
        end
        if vst2 and vst3 then break end
      end
      io.close(file)
    end
  end
  -- check for JSFX presence
  local file = io.open (jsfx_ini)
  local cntrl, src, ltcntrl = false, false, false
  for line in file:lines() do
    if line:match("AB_LM_cntrl") then
      cntrl = true
    elseif line:match("AB_LMLT_cntrl") then
      ltcntrl = true
    elseif line:match("AB_LM_src") then
      src = true
    end
    if cntrl and src and ltcntrl then 
      jsfx = 1
      break 
    end
  end
  io.close(file)
  if not vst2 and not vst3 and not jsfx then
    reaper.MB( "No AB_LM VST2/VST3/JSFX has been found on your system.", "Can't run the action!", 0 )
    local prev = reaper.HasExtState( "AB_LM Toggle", "format" )
    if prev then
      reaper.DeleteExtState( "AB_LM Toggle", "format", true )
    end
    reaper.defer(function() end)
    return
  end
  -- what to do if preference does not exist
  if pref == 1 and not jsfx then
    pref = vst2 and vst2 or vst3
  elseif pref == 2 and not vst2 then
    pref = vst3 and vst3 or jsfx
  elseif pref == 3 and not vst3 then
    pref = vst2 and vst2 or jsfx
  end
  reaper.SetExtState( "AB_LM Toggle", "format", pref, true )
else
  pref = tonumber(reaper.GetExtState( "AB_LM Toggle", "format" ))
end

------------------------------------------------------------------------------------------------
local function GetInfo()
  local FX_win = reaper.JS_Window_Find("FX: ", false )
  if FX_win then
    local title = reaper.JS_Window_GetTitle( FX_win, "" )
    if title:match("FX: Track ") or title:match("FX: Master Track") or title:match("FX: Item ") then
      local what, trackGUID, take
      reaper.JS_Window_SetForeground( FX_win ) -- GetFocusedFX works better
      local focus, track, item, fxid = reaper.GetFocusedFX()
      if focus == 1 then
        what = "track"
        if track == 0 then
          track = reaper.GetMasterTrack(0)
        else
          track = reaper.GetTrack(0, track-1)
        end
        trackGUID = reaper.guidToString(reaper.GetTrackGUID(track), "")
      elseif focus == 2 then
        what = "item"
        item = reaper.GetMediaItem(0, item)
        track = reaper.GetMediaItemTrack(item)
        trackGUID = reaper.guidToString(reaper.GetTrackGUID(track), "")
        take = reaper.GetMediaItemTake(item, fxid >> 16)
      end
      return fxid, track, what, trackGUID, take, FX_win
    else
      return nil
    end
  end
end

------------------------------------------------------------------------------------------------
local function AddTrackAB(track, pos, x)
  if pref == 1 then
    if x == 1 then
      reaper.TrackFX_AddByName(track, "JS:AB_LM_src", false, -1)
    else
      if lite == 1 then
        reaper.TrackFX_AddByName(track, "JS:AB_LMLT_cntrl", false, -1)
      else
        reaper.TrackFX_AddByName(track, "JS:AB_LM_cntrl", false, -1)
      end
    end
  elseif pref == 2 then
    reaper.TrackFX_AddByName(track, "VST2:AB_LM", false, -1)
  elseif pref == 3 then
    reaper.TrackFX_AddByName(track, "VST3:AB_LM", false, -1)
  end
  reaper.TrackFX_CopyToTrack(track, reaper.TrackFX_GetCount( track )-1, track, pos, true )
end

local function AddTakeAB(take, pos, x)
 if pref == 1 then
   if x == 1 then
     reaper.TakeFX_AddByName(take, "JS:AB_LM_src", -1)
   else
     if lite == 1 then
       reaper.TakeFX_AddByName(take, "JS:AB_LMLT_cntrl", -1)
     else
       reaper.TakeFX_AddByName(take, "JS:AB_LM_cntrl", -1)
     end
   end 
  elseif pref == 2 then
    reaper.TakeFX_AddByName( take, "VST2:AB_LM", -1 )
  elseif pref == 3 then
    reaper.TakeFX_AddByName( take, "VST3:AB_LM", -1 )
  end
  reaper.TakeFX_CopyToTake( take, reaper.TakeFX_GetCount( take )-1, take, pos, true )
end

------------------------------------------------------------------------------------------------
local function AlterChunk(chunk, fxid, t)
  local cnt = -1
  local float = false
  for line in chunk:gmatch('[^\n]+') do
    if cnt == -1 and line:match("^SHOW %d+$") then -- keep previously focused FX focused
      line = "SHOW " .. tostring(fxid+2)
      cnt = 0
    end
    if pref ~= 1 then -- VST
      if line:match("<VST.-AB_LM") and cnt < 2 then
        if cnt == 0 then
          line = line:gsub('(.-)""(.+)', '%1"-- AB_LM Send --"%2')
          cnt = cnt + 1
        else
          line = line:gsub('(.-)""(.+)', '%1"-- AB_LM Receive --"%2')
          cnt = cnt + 1
        end
      elseif not float and cnt == 2 and line:match("FLOATPOS") then -- float AB_LM Receive
        line = "FLOAT 1230 180 440 671"
        float = true
      end
    else -- JSFX
      if line:match("<JS.-AB_LM_src") and cnt < 1 then
        line = line:gsub('(.-)""', '%1"-- AB_LM Send --"')
        cnt = cnt + 1
      elseif (line:match("<JS.-AB_LM_cntrl") or line:match("<JS.-AB_LMLT_cntrl")) and cnt < 2 then
        line = line:gsub('(.-)""', '%1"-- AB_LM Receive --"')
        cnt = cnt + 1
      elseif not float and cnt == 2 and line:match("FLOATPOS") then -- float AB_LM Receive
        line = "FLOAT 1052 56 573 956"
        float = true
      end
    end
    t[#t+1] = line
  end
end

------------------------------------------------------------------------------------------------
local function InsertAB(fxid, track, what, trackGUID, take)
  if what == "track" then
    AddTrackAB(track, 0, 1)
    AddTrackAB(track, reaper.TrackFX_GetCount( track ), 2)
    local _, chunk = reaper.GetTrackStateChunk( track, "", false )
    local t = {}
    AlterChunk(chunk, fxid, t)
    chunk = table.concat(t, "\n")
    reaper.SetTrackStateChunk( track, chunk, false )
  elseif what == "item" then
    AddTakeAB(take, 0, 1)
    AddTakeAB(take, reaper.TakeFX_GetCount( take ), 2)
    local item = reaper.GetMediaItemTake_Item( take )
    local _, chunk = reaper.GetItemStateChunk( item, "", false )
    local t = {}
    AlterChunk(chunk, fxid, t)
    chunk = table.concat(t, "\n")
    reaper.SetItemStateChunk( item, chunk, false )
  end
end

------------------------------------------------------------------------------------------------
local function RemoveAB(track, what, take)
  if what == "track" then
    local id = reaper.TrackFX_GetByName( track, "-- AB_LM Receive --", false )
    reaper.TrackFX_Delete( track, id)
    id = reaper.TrackFX_GetByName( track, "-- AB_LM Send --", false )
    reaper.TrackFX_Delete( track, id)
  elseif what == "item" then
    local id = reaper.TakeFX_AddByName( take, "-- AB_LM Receive --", 0 )
    reaper.TakeFX_Delete( take, id )
    id = reaper.TakeFX_AddByName( take, "-- AB_LM Send --", 0 )
    reaper.TakeFX_Delete( take, id )
  end
end

-- Main function -------------------------------------------------------------------------------
local fxid, track, what, trackGUID, take, FX_win = GetInfo()
if track and trackGUID then
  local _, left, top, right, bottom = reaper.JS_Window_GetRect( FX_win )
  local width = right - left
  local height = bottom - top
  local ok, value = reaper.GetProjExtState(0, "AB_LM Toggle", trackGUID)
  if ok and value == "1" then
    reaper.Undo_BeginBlock()
    RemoveAB(track, what, take)
    reaper.SetProjExtState(0, "AB_LM Toggle", trackGUID, "0")
    reaper.Undo_EndBlock("Remove AB_LM from focused FX Chain", -1)
  else
    reaper.Undo_BeginBlock()
    InsertAB(fxid, track, what, trackGUID, take)
    reaper.SetProjExtState(0, "AB_LM Toggle", trackGUID, "1")
    reaper.Undo_EndBlock("Enclose selected/focused FX in Chain with AB_LM", -1)
  end
  reaper.JS_Window_SetPosition( FX_win, left, top, width, height )
else
  reaper.defer(function() end)
end

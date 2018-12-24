-- @description amagalma_Toggle enclose selected or focused FX in vsible chain with AB_LM Level Matching VST
-- @author amagalma
-- @version 1.05
-- @about
--   # Inserts or Removes TBProAudio's AB_LM Level Matching VST enclosing the selected FX or the focused FX (if not any selected)
--   - Smart undo point creation
--   - Automatically checks if AB_LM VST2 or VST3 is present in your system
-- @link http://www.tb-software.com/TBProAudio/ab_lm.html

--[[
 * Changelog:
 * v1.05(2018-12-24)
  + float AB_LM Receive
--]]

------------------------------------------------------------------------------------------------
local reaper = reaper

------------------------------------------------------------------------------------------------

-- INITIAL CHECKS
-- Check if js_ReaScriptAPI extension is installed
local js_vers = reaper.JS_ReaScriptAPI_Version()
if js_vers < 0.962 then
  reaper.MB( "You need js_ReaScriptAPI extension (v0.962 and newer) to run this script.", "Cannot run script!", 0 )
  reaper.defer(function() end)
  return
end

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
  reaper.defer(function() end)
  return
end

------------------------------------------------------------------------------------------------
local function GetInfo()
  local FX_win = reaper.JS_Window_Find("FX: ", false )
  local sel_FX, firstselFX, lastselFX = {}
  if FX_win then
    local title = reaper.JS_Window_GetTitle( FX_win, "" )
    if title:match("FX: Track ") or title:match("FX: Master Track") or title:match("FX: Item ") then
      local list = reaper.JS_Window_FindChildByID(FX_win, 1076)
      local _, sel_fx = reaper.JS_ListView_ListAllSelItems(list)
      local a = 0
      local sel_FX = {}
      for i in sel_fx:gmatch("%d+") do
        sel_FX[a+1] = tonumber(i)
        a = a + 1
      end
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
      if #sel_FX > 1 then
        firstselFX = sel_FX[1]
        lastselFX = sel_FX[#sel_FX]
      end
      return fxid, track, what, trackGUID, take, firstselFX, lastselFX
    else
      return nil
    end
  end
end

------------------------------------------------------------------------------------------------
local function AddTrackAB(track, pos)
  if vst == 2 then
    reaper.TrackFX_AddByName(track, "VST2:AB_LM", false, -1)
  elseif vst == 3 then
    reaper.TrackFX_AddByName(track, "VST3:AB_LM", false, -1)
  end
  reaper.TrackFX_CopyToTrack(track, reaper.TrackFX_GetCount( track )-1, track, pos, true )
end

local function AddTakeAB(take, pos)
  if vst == 2 then
    reaper.TakeFX_AddByName( take, "VST2:AB_LM", -1 )
  elseif vst == 3 then
    reaper.TakeFX_AddByName( take, "VST3:AB_LM", -1 )
  end
  reaper.TakeFX_CopyToTake( take, reaper.TakeFX_GetCount( take )-1, take, pos, true )
end

------------------------------------------------------------------------------------------------
local function InsertAB(fxid, track, what, trackGUID, take, firstselFX, lastselFX)
  local focusedFX = fxid
  if lastselFX and focusedFX >= firstselFX and focusedFX <= lastselFX then
    focusedFX = fxid + 1
  elseif lastselFX and focusedFX > lastselFX then
    focusedFX = fxid + 2
  end
  if what == "track" then
    if lastselFX then -- enclose selected FXs
      AddTrackAB(track, firstselFX)
      AddTrackAB(track, lastselFX+2)
    else -- enclose focused FX
      AddTrackAB(track, fxid)
      AddTrackAB(track, fxid+2)
    end
    local _, chunk = reaper.GetTrackStateChunk( track, "", false )
    local t = {}
    local cnt = 0
    for line in chunk:gmatch('[^\n]+') do       
      if line:match("<VST.-AB_LM") and cnt < 2 then
        if cnt == 0 then
          line = line:gsub('(.-)""(.+)', '%1"-- AB_LM Send --"%2')
          cnt = cnt + 1
        else
          line = line:gsub('(.-)""(.+)', '%1"-- AB_LM Receive --"%2')
          cnt = cnt + 1
        end
      end
      t[#t+1] = line
    end
    chunk = table.concat(t, "\n")
    reaper.SetTrackStateChunk( track, chunk, false )
    reaper.TrackFX_Show( track, lastselFX ~= nil and lastselFX+2 or fxid+2, 3 ) -- float AB_LM Receive
    reaper.TrackFX_SetOpen( track, lastselFX ~= nil and focusedFX or fxid+1, true ) -- keep previously focused FX focused
  elseif what == "item" then
    if lastselFX then -- enclose selected FXs
      AddTakeAB(take, firstselFX)
      AddTakeAB(take, lastselFX+2)
    else -- enclose focused FX
      AddTakeAB(take, fxid)
      AddTakeAB(take, fxid+2)
    end
    local item = reaper.GetMediaItemTake_Item( take )
    local _, chunk = reaper.GetItemStateChunk( item, "", false )
    local t = {}
    local cnt = 0
    for line in chunk:gmatch('[^\n]+') do       
      if line:match("<VST.-AB_LM") and cnt < 2 then
        if cnt == 0 then
          line = line:gsub('(.-)""(.+)', '%1"-- AB_LM Send --"%2')
          cnt = cnt + 1
        else
          line = line:gsub('(.-)""(.+)', '%1"-- AB_LM Receive --"%2')
          cnt = cnt + 1
        end
      end
      t[#t+1] = line
    end
    chunk = table.concat(t, "\n")
    reaper.SetItemStateChunk( item, chunk, false )
    reaper.TakeFX_Show( take, lastselFX ~= nil and lastselFX+2 or fxid+2, 3 ) -- float AB_LM Receive
    reaper.TakeFX_SetOpen( take, lastselFX ~= nil and focusedFX or fxid+1, true ) -- keep previously focused FX focused
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
local fxid, track, what, trackGUID, take, firstselFX, lastselFX = GetInfo()
if track and trackGUID then
  local ok, value = reaper.GetProjExtState(0, "AB_LM VST Toggle", trackGUID)
  if ok and value == "1" then
    reaper.Undo_BeginBlock()
    RemoveAB(track, what, take)
    reaper.SetProjExtState(0, "AB_LM VST Toggle", trackGUID, "0")
    reaper.Undo_EndBlock("Remove AB_LM VST from focused FX Chain", -1)
  else
    reaper.Undo_BeginBlock()
    InsertAB(fxid, track, what, trackGUID, take, firstselFX, lastselFX)
    reaper.SetProjExtState(0, "AB_LM VST Toggle", trackGUID, "1")
    reaper.Undo_EndBlock("Enclose selected/focused FX in Chain with AB_LM VST", -1)
  end
else
  reaper.defer(function() end)
end

-- @description Copy - Paste the selected or all the FX from the focused FX chain to all the selected items or tracks
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=290715
-- @screenshot https://i.ibb.co/SQRQDhw/Show.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Copies and pastes the selected (or all the FX in chain, if there is not a selection) from the focused FX chain to all the selected items or tracks.
--
--   - Requires js_ReaScriptAPI and ReaImGui


if not reaper.ImGui_GetBuiltinPath then
  return reaper.MB('ReaImGui is not installed or too old.', 'Error!', 0)
end
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.0.2'



local function GetSelectedListItems( windowTitle )
  local FX_win = reaper.JS_Window_Find( windowTitle, true )
  if not FX_win then return end
  local sel_FX = {}
  local list = reaper.JS_Window_FindChildByID( FX_win, 1076 )
  local sel_nr, sel_fx = reaper.JS_ListView_ListAllSelItems( list )
  local fx_cnt = 0
  if sel_nr ~= 0 then
    for i in sel_fx:gmatch("%d+") do
      sel_FX[fx_cnt+1] = tonumber(i)
      fx_cnt = fx_cnt + 1
    end
  else -- if none selected, consider as all selected
    fx_cnt = reaper.JS_ListView_GetItemCount( list )
    for i = 1, fx_cnt do
      sel_FX[i] = i-1
    end
  end
  return sel_FX, fx_cnt
end


local function GetInfo()
  local retval, trackidx, itemidx, takeidx = reaper.GetTouchedOrFocusedFX( 1 )
  if retval == false then return end
  local what, sel_FX, fx_cnt
  local isMaster = trackidx == -1
  local track = isMaster and reaper.GetMasterTrack( 0 ) or reaper.GetTrack( 0, trackidx )
  local GUIDS = {}
  if takeidx ~= -1 then -- Item
    local item = reaper.GetTrackMediaItem( track, itemidx )
    local take = reaper.GetTake( item, takeidx )
    local name = reaper.GetTakeName( take )
    local search = string.format("FX: Item%s", name == "" and "" or (' "' .. name .. '"'))
    sel_FX, fx_cnt = GetSelectedListItems( search )
    for i = 1, fx_cnt do
       GUIDS[reaper.TakeFX_GetFXGUID( take, sel_FX[i] )] = true
    end
    return {what = "Take", obj = take, fx = GUIDS, cnt = fx_cnt}
  else
    if isMaster then
      sel_FX, fx_cnt = GetSelectedListItems( "FX: Master Track" )
    else -- normal Track
      local _, name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
      local search = string.format("FX: Track %i%s", trackidx+1, name == "" and "" or (' "' .. name .. '"'))
      sel_FX, fx_cnt = GetSelectedListItems( search )
      for i = 1, fx_cnt do
         GUIDS[reaper.TrackFX_GetFXGUID( track, sel_FX[i] )] = true
      end
      return {what = "Track", obj = track, fx = GUIDS}
    end
  end
end


local data = GetInfo()
if not data then 
  return reaper.MB( "Could not get the focused FX chain.\nPlease, click it to focus and run again.",
         "Aborting..", 0 )
end


local open, visible -- Needed up here for the NotValid() to be able to affect the ImGui window


local function Undo( func, descchange, flags )
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  func()
  reaper.PreventUIRefresh( -1 )
  reaper.Undo_EndBlock2( 0 , descchange, flags )
end


local function NotValid(ptr)
  if not reaper.ValidatePtr2( 0, data.obj, ptr ) then
    open = false
    reaper.MB("The source FX are no longer valid!", "Quitting..", 0)
    return true
  end
end


local function FromTrackToItem()
  if NotValid("MediaTrack*") then return end
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    local take = reaper.GetActiveTake( item )
    if not take then return end
    local fx_cnt = reaper.TakeFX_GetCount( take ) - 1
    local c = 0
    for j = 0, reaper.TrackFX_GetCount( data.obj ) - 1 do
      local GUID = reaper.TrackFX_GetFXGUID( data.obj, j )
      if data.fx[GUID] then
        c = c + 1
        reaper.TrackFX_CopyToTake( data.obj, j, take, fx_cnt + c, false )
      end
    end
  end
end


local function FromTrackToTrack()
  if NotValid("MediaTrack*") then return end
  for i = 0, reaper.CountSelectedTracks2(0, true)-1 do
    local track = reaper.GetSelectedTrack2( 0, i, true )
    local fx_cnt = reaper.TrackFX_GetCount( track ) - 1
    local c = 0
    for j = 0, reaper.TrackFX_GetCount( data.obj ) - 1 do
      local GUID = reaper.TrackFX_GetFXGUID( data.obj, j )
      if data.fx[GUID] then
        c = c + 1
        reaper.TrackFX_CopyToTrack( data.obj, j, track, fx_cnt + c, false )
      end
    end
  end
end


local function FromItemToItem()
  if NotValid("MediaItem_Take*") then return end
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    local take = reaper.GetActiveTake( item )
    if not take then return end
    local fx_cnt = reaper.TakeFX_GetCount( take ) - 1
    local c = 0
    for j = 0, reaper.TakeFX_GetCount( data.obj ) - 1 do
      local GUID = reaper.TakeFX_GetFXGUID( data.obj, j )
      if data.fx[GUID] then
        c = c + 1
        reaper.TakeFX_CopyToTake( data.obj, j, take, fx_cnt + c, false )
      end
    end
  end
end


local function FromItemToTrack()
  if NotValid("MediaItem_Take*") then return end
  for i = 0, reaper.CountSelectedTracks2(0, true)-1 do
    local track = reaper.GetSelectedTrack2( 0, i, true )
    local fx_cnt = reaper.TrackFX_GetCount( track ) - 1
    local c = 0
    for j = 0, reaper.TakeFX_GetCount( data.obj ) - 1 do
      local GUID = reaper.TakeFX_GetFXGUID( data.obj, j )
      if data.fx[GUID] then
        c = c + 1
        reaper.TakeFX_CopyToTrack( data.obj, j, track, fx_cnt + c, false )
      end
    end
  end
end


-----------------------------------------------------------------------------------------------------


local ctx = ImGui.CreateContext('Copy/Paste selected FX', ImGui.ConfigFlags_NoSavedSettings)
local sans_serif = ImGui.CreateFont('sans-serif', 16)
ImGui.Attach(ctx, sans_serif)


local text = 'Choose the items or tracks where\nyou want to paste the selected FX'
local text2 = "Paste to:"
local timer, indent = 0, 0


local function myWindow()
  ImGui.Text( ctx, text )
  ImGui.Spacing( ctx )
  ImGui.Separator( ctx )
  if timer ~= 2 then
    timer = timer + 1
    indent = (ImGui.GetContentRegionAvail(ctx) - ImGui.CalcTextSize( ctx, text2 ))/2
  end
  ImGui.Indent( ctx, indent )
  ImGui.Text( ctx, text2 )
  ImGui.Unindent( ctx, indent )
  ImGui.Spacing( ctx )
  if ImGui.Button(ctx, 'Selected Items') then
    if data.what == "Take" then
      Undo( FromItemToItem, "Copy TakeFX to Items", 4 )
    else
      Undo( FromTrackToItem, "Copy TrackFX to Items", 4 )
    end
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Selected Tracks') then
    if data.what == "Take" then
      Undo( FromItemToTrack, "Copy TakeFX to Tracks", 2 )
    else
      Undo( FromTrackToTrack, "Copy TrackFX to Tracks", 2 )
    end
  end
  ImGui.Spacing( ctx )
end


local window_flags = ImGui.WindowFlags_NoCollapse|ImGui.WindowFlags_NoDocking|
      ImGui.WindowFlags_NoResize|ImGui.WindowFlags_NoSavedSettings|ImGui.WindowFlags_TopMost
local x, y = reaper.GetMousePosition()
ImGui.SetNextWindowPos( ctx, x, y, 0, 0.5, 0)
local window_name = 'Paste copied ' .. data.what .. " FX"


local function loop()
  ImGui.PushFont(ctx, sans_serif)
  visible, open = ImGui.Begin(ctx, window_name, true, window_flags)
  if visible then
    myWindow()
    ImGui.End(ctx)
  end
  ImGui.PopFont(ctx)

  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

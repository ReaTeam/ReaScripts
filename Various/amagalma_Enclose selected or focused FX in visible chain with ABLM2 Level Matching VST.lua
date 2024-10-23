-- @description Enclose selected or focused FX in visible chain with ABLM2 Level Matching VST
-- @author amagalma
-- @version 1.00
-- @link https://www.tbproaudio.de/products/ablm
-- @link https://forum.cockos.com/showthread.php?t=215215
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Inserts TBProAudio's ABLM2 Level Matching VST enclosing the selected FXs or the focused FX (if not any selected)
--   - Ability to rename the send and receive instances with custom names (inside the script)
--   - Supports multiple instances per FX chain, automatically numbered
--   - Smart undo point creation
--   - Requires JS_ReaScriptAPI


-- USER SETTINGS ===========================
local receive_name = "ABLM2 Receive"
local send_name = "ABLM2 Send"
-- =========================================

------------------------------------------------------------------------------------------------

-- Check if JS_ReaScriptAPI is installed
if not reaper.APIExists("JS_ReaScriptAPI_Version") then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then
    reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else
    reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end

-- Check for VST2/3 presence
local exists, format = false
local function SearchIni( vst_ini )
  if reaper.file_exists( vst_ini ) then
    local file = io.open( vst_ini )
    if file then
      for line in file:lines() do
        if line:match("ABLM2") then
          if line:match("dll") then
            exists = true
            format = 2
            break
          elseif line:match("vst3") then
            exists = true
            format = 3
            break
          end
        end
      end
      io.close( file )
    end  
  end
end

local sep = (reaper.GetOS()):match("Win") == "Win" and "\\" or "/"
if (reaper.GetAppVersion()):match("64") == "64" then -- Reaper is 64bit
  SearchIni( reaper.GetResourcePath() .. sep .."reaper-vstplugins64.ini" )
end
if not exists then
  SearchIni( reaper.GetResourcePath() .. sep .."reaper-vstplugins.ini" )
end
if not exists then
  reaper.MB( "It appears that ABLM2 VST is not installed in your system.\nPlease, install and run again.", "Exiting...", 0 )
  reaper.defer(function() end)
  return
end

------------------------------------------------------------------------------------------------
local last_ablm = 0

local function GetLastABLM( name )
  if name:find( receive_name, 4, true ) or name:find( send_name, 4, true ) then
    local cur = tonumber( name:match(".- (%d+) %]%-%-$") )
    if cur and cur > last_ablm then 
      last_ablm = cur
    end
  end
end


local function GetInfo()
  local number, window_list = reaper.JS_Window_ListFind("FX: ", false)
  if number == 0 then return nil end
  for address in window_list:gmatch("[^,]+") do
    local FX_win = reaper.JS_Window_HandleFromAddress(address)
    local title = reaper.JS_Window_GetTitle(FX_win)
    if title:match("FX: Track ") or title:match("FX: Master Track") or title:match("FX: Item ") then
      local sel_FX, firstselFX, lastselFX = {}
      local list = reaper.JS_Window_FindChildByID(FX_win, 1076)
      local _, sel_fx = reaper.JS_ListView_ListAllSelItems(list)
      local a = 0
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
        for fx = 0, reaper.TrackFX_GetCount( track )-1 do
          local ok, name = reaper.TrackFX_GetFXName( track, fx, "" )
          if ok then GetLastABLM( name ) end
        end
      elseif focus == 2 then
        what = "item"
        item = reaper.GetMediaItem(0, item)
        track = reaper.GetMediaItemTrack(item)
        trackGUID = reaper.guidToString(reaper.GetTrackGUID(track), "")
        take = reaper.GetMediaItemTake(item, fxid >> 16)
        for fx = 0, reaper.TakeFX_GetCount( take )-1 do
          local ok, name = reaper.TakeFX_GetFXName( take, fx, "" )
          if ok then GetLastABLM( name ) end
        end
      end
      if #sel_FX > 1 then
        firstselFX = sel_FX[1]
        lastselFX = sel_FX[#sel_FX]
      end
      return fxid, track, what, trackGUID, take, firstselFX, lastselFX, FX_win
    end
  end
end

------------------------------------------------------------------------------------------------

local function AddTrackAB(track, pos, x)
  if format == 2 then
    reaper.TrackFX_AddByName(track, "VST2:ABLM2", false, -1)
  else
    reaper.TrackFX_AddByName(track, "VST3:ABLM2", false, -1)
  end
  reaper.TrackFX_CopyToTrack(track, reaper.TrackFX_GetCount( track )-1, track, pos, true )
end

local function AddTakeAB(take, pos, x)
  if format == 2 then
    reaper.TakeFX_AddByName( take, "VST2:ABLM2", -1 )
  else
    reaper.TakeFX_AddByName( take, "VST3:ABLM2", -1 )
  end
  reaper.TakeFX_CopyToTake( take, reaper.TakeFX_GetCount( take )-1, take, pos, true )
end

------------------------------------------------------------------------------------------------

local function AlterChunk(chunk, lastselFX, focusedFX, fxid, t)
  local cnt = -1
  local float = false
  for line in chunk:gmatch('[^\n]+') do
    if cnt == -1 and line:match("^SHOW %d+$") then -- keep previously focused FX focused
      line = "SHOW " .. tostring(lastselFX ~= nil and focusedFX+1 or fxid+2)
      cnt = 0
    end
    if line:match("<VST.-ABLM2") and cnt < 2 then
      if not line:find("--[ " .. receive_name, 44, true) and 
         not line:find("--[ " .. send_name, 44, true )
      then
        if cnt == 0 then
          line = line:gsub('(.-)""(.+)', '%1"--[ '..send_name..' '..tostring(last_ablm+1)..' ]--"%2')
          cnt = cnt + 1
        else
          line = line:gsub('(.-)""(.+)', '%1"--[ '..receive_name..' '..tostring(last_ablm+1)..' ]--"%2')
          cnt = cnt + 1
        end
      end
    elseif not float and cnt == 2 and line:match("FLOATPOS") then -- float ABLM2 Receive
      line = "FLOAT 1230 180 440 679"
      float = true
    end
    t[#t+1] = line
  end
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
      AddTrackAB(track, firstselFX, 1)
      AddTrackAB(track, lastselFX+2, 2)
    else -- enclose focused FX
      AddTrackAB(track, fxid, 1)
      AddTrackAB(track, fxid+2, 2)
    end
    local _, chunk = reaper.GetTrackStateChunk( track, "", false )
    local t = {}
    AlterChunk(chunk, lastselFX, focusedFX, fxid, t)
    chunk = table.concat(t, "\n")
    reaper.SetTrackStateChunk( track, chunk, false )
  elseif what == "item" then
    if lastselFX then -- enclose selected FXs
      AddTakeAB(take, firstselFX, 1)
      AddTakeAB(take, lastselFX+2, 2)
    else -- enclose focused FX
      AddTakeAB(take, fxid, 1)
      AddTakeAB(take, fxid+2, 2)
    end
    local item = reaper.GetMediaItemTake_Item( take )
    local _, chunk = reaper.GetItemStateChunk( item, "", false )
    local t = {}
    AlterChunk(chunk, lastselFX, focusedFX, fxid, t)
    chunk = table.concat(t, "\n")
    reaper.SetItemStateChunk( item, chunk, false )
  end
end

-- Main function -------------------------------------------------------------------------------

local fxid, track, what, trackGUID, take, firstselFX, lastselFX, FX_win = GetInfo()
if track and trackGUID then
  local _, left, top, right, bottom = reaper.JS_Window_GetRect( FX_win )
  local width = right - left
  local height = bottom - top
  reaper.Undo_BeginBlock()
  InsertAB(fxid, track, what, trackGUID, take, firstselFX, lastselFX)
  reaper.Undo_EndBlock("Enclose selected/focused FX in Chain with ABLM2", 2)
  reaper.JS_Window_SetPosition( FX_win, left, top, width, height )
else
  reaper.defer(function() end)
end

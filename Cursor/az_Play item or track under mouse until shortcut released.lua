-- @description Play item or track under mouse until shortcut released
-- @author AZ
-- @version 1.0
-- @provides az_Play item or track under mouse until shortcut released/speaker.cur
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   #Play item or track under mouse until shortcut released
--
--   The script is written to be replacement of SWS action
--   SWS/BR: Play from mouse cursor position and solo item and track under mouse for the duration (perform until shortcut released)
--
--   My script works fine in heavy projects, has  improved solo/mute logic and doesn't produce extra loud sounds.
--   Also it doesn't stop recording.

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

---Getting pressed key---
local start_time = reaper.time_precise()
local key_state = reaper.JS_VKeys_GetState(start_time - 2)
local KEY = {}

for i = 1, 255 do
  if key_state:byte(i) ~= 0 then table.insert(KEY, i) end
end

local path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]
local folder = "az_Play item or track under mouse until shortcut released"

----------
function Key_held()
    key_state = reaper.JS_VKeys_GetState(start_time - 2)
    local ret = 0
    for i, v in ipairs(KEY) do
      ret = ret + key_state:byte(v)
    end
    return ret == #KEY 
end
---------------

function GetPrefs(key) -- key need to be a string as in Reaper ini file
  local retval, buf = reaper.get_config_var_string( key )
  if retval == true then return tonumber(buf) end
end

---------------

function Release()
  reaper.PreventUIRefresh(1)
  
  if playState ~= 5 then reaper.OnStopButtonEx(0) end
  
  local startReleaseTime = reaper.time_precise()
  local currentTime = reaper.time_precise()
  local anticipative = GetPrefs('workrender') & 1
  local waitTime = reaper.GetOutputLatency()
  
  if anticipative == 1 then
    local buffer = GetPrefs('renderaheadlen') / 1000
    waitTime = waitTime + buffer
  end
  
  while currentTime <= startReleaseTime + waitTime do
    currentTime = reaper.time_precise()
  end
  
  RestoreSoloMute()
  RestorePlayState()
  
  
  for i, v in ipairs(KEY) do
    reaper.JS_VKeys_Intercept(v, -1)
  end

  reaper.PreventUIRefresh(-1)
end

------------------

function SavePlayState()
  playState = reaper.GetPlayStateEx(0)
  curPos = reaper.GetCursorPosition()
  playPos = reaper.GetPlayPositionEx(0)
end

------------------

function RestorePlayState()
  if playState ~= 5 then
    
    if playState ~= 0 or playState ~= 2 then
      reaper.SetEditCurPos(playPos, false, false)
      if playState == 1 then reaper.OnPlayButtonEx(0) end
    end
    reaper.SetEditCurPos(curPos, false, false)
  end
end

---------------------

function GetTopBottomItemHalf()
local itempart
local x, y = reaper.GetMousePosition()

local item_under_mouse = reaper.GetItemFromPoint(x,y,true)

if item_under_mouse then

  local item_h = reaper.GetMediaItemInfo_Value( item_under_mouse, "I_LASTH" )
  
  local OScoeff = 1
  if reaper.GetOS():match("^Win") == nil then
    OScoeff = -1
  end
  
  local test_point = math.floor( y + (item_h-1) *OScoeff)
  local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
  
  if item_under_mouse == test_item then
    itempart = "header"
  else
    local test_point = math.floor( y + item_h/2 *OScoeff)
    local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
    
    if item_under_mouse ~= test_item then
      itempart = "bottom"
    else
      itempart = "top"
    end
  end

  return item_under_mouse, itempart
else return nil
end

end

--------------------

function UnmuteRecursive(track) 
  local parentSend = reaper.GetMediaTrackInfo_Value( track, 'B_MAINSEND' ) 
  
  reaper.SetMediaTrackInfo_Value( track, 'B_MUTE', 0 )
  
  if parentSend ~= 1 then
    local hwocnt = reaper.GetTrackNumSends( track, 1 )
    local hwo = hwocnt 
    for i = 1, hwocnt do --check hardware outputs
      local hwomute = reaper.GetTrackSendInfo_Value( track, 1, i-1 , 'B_MUTE' )
      if hwomute ~= 0 then hwo = hwo - 1 end
    end
    
    if hwo <= 0 then -- check sends
      local sndcnt = reaper.GetTrackNumSends( track, 0 )
      for i = 1, sndcnt do --check hardware outputs
        local sndmute = reaper.GetTrackSendInfo_Value( track, 0, i-1 , 'B_MUTE' )
        if sndmute == 0 then
          local sndtr = reaper.GetTrackSendInfo_Value( track, 0, i-1 , 'P_DESTTRACK' )
          UnmuteRecursive(sndtr)
        end
      end 
    end
  else
    local parentTrack = reaper.GetParentTrack(track)
    if parentTrack then UnmuteRecursive(parentTrack) end 
  end
end

--------------------

function ToggleSoloMute()
  local item, half = GetTopBottomItemHalf()
  
  local alltrcnt = reaper.CountTracks(0)
  for i = 0, alltrcnt -1 do
    local track = reaper.GetTrack(0, i) 
    local solostate = reaper.GetMediaTrackInfo_Value( track, 'I_SOLO' )
    local mutestate = reaper.GetMediaTrackInfo_Value( track, 'B_MUTE' )
    TracksStates[tostring(track)] = {}
    local trdata = TracksStates[tostring(track)]
    trdata.solo = solostate
    trdata.mute = mutestate
    trdata.tr = track
    
    if track ~= track_mouse and solostate ~= 5 then
      if solostate == 6 then reaper.SetMediaTrackInfo_Value( track, 'I_SOLO', 5 )
      else reaper.SetMediaTrackInfo_Value( track, 'I_SOLO', 0 )
      end
    end
    
    if track == track_mouse then
      reaper.SetMediaTrackInfo_Value( track_mouse, 'I_SOLO', 2 ) -- 2 means soloed in place
    end
  end
   
  UnmuteRecursive(track_mouse)
  
  if item and half ~= 'header' then 
    for i = 0, reaper.CountTrackMediaItems(track_mouse) -1 do
      local item = reaper.GetTrackMediaItem(track_mouse, i)
      reaper.SetMediaItemInfo_Value(item, 'C_MUTE_SOLO', 1)
      table.insert(MutedItems, item)
    end
    reaper.SetMediaItemInfo_Value(item, 'C_MUTE_SOLO', -1)
  end
end

------------------

function RestoreSoloMute()
  for i, item in ipairs(MutedItems) do 
    reaper.SetMediaItemInfo_Value(item, 'C_MUTE_SOLO', 0)
  end 
  for i, v in pairs(TracksStates) do
    reaper.SetMediaTrackInfo_Value( v.tr, 'I_SOLO', v.solo )
    reaper.SetMediaTrackInfo_Value( v.tr, 'B_MUTE', v.mute )
  end
end

------------------

function Main()
  
  reaper.JS_Mouse_SetCursor(cursor)
  
  if Key_held() then
    if not init then
      reaper.PreventUIRefresh(1)
      SavePlayState()
      if playState ~= 5 then reaper.OnStopButtonEx(0) end
      if track_mouse then
        --local status, err = xpcall(ToggleSoloMute, debug.traceback)
        ToggleSoloMute()
      end
      if playState ~= 5 then
        reaper.SetEditCurPos(reaper.BR_PositionAtMouseCursor(true), false, false)
        reaper.OnPlayButtonEx(0)
        reaper.SetEditCurPos(curPos, false, false)
      end 
      reaper.PreventUIRefresh(-1)
      init = true
    end
     
    reaper.defer(Main)
  else reaper.atexit(Release)
  end
  
end

--------------------
----------START-----------
if reaper.APIExists( 'BR_GetMouseCursorContext' ) ~= true then
  reaper.ShowMessageBox('Please, install SWS extension!', 'No SWS extension', 0)
  return
end

if reaper.APIExists( 'JS_Mouse_LoadCursorFromFile' ) ~= true then
  reaper.ShowMessageBox('Please, install js_ReaScriptAPI extension!', 'No js_ReaScriptAPI extension', 0)
  return
end

cursor = reaper.JS_Mouse_LoadCursorFromFile(path..folder..'/speaker.cur')

local x, y = reaper.GetMousePosition()
track_mouse, info = reaper.GetThingFromPoint( x, y )

local window, segment, details = reaper.BR_GetMouseCursorContext()

if window == 'arrange' or window == 'ruler' then
  
  for i, v in ipairs(KEY) do
    reaper.JS_VKeys_Intercept(v, 1)
  end
  
  if #KEY == 0 then return end
  
  MutedItems = {}
  TracksStates = {}
  Main()

end

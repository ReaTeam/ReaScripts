-- @description Phase align two selected items by moving item's contents (using CFE), depending on mouse position
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about - Requires JS_ReaScriptAPI

local item_cnt = reaper.CountSelectedMediaItems(0)
if item_cnt ~= 2 then
  reaper.MB( "Please, select just two media items.", "Aborting..", 0 )
  return reaper.defer(function() end)
end

local first_item = reaper.GetSelectedMediaItem( 0, 0 )
local first_item_take = reaper.GetActiveTake( first_item )
local second_item = reaper.GetSelectedMediaItem( 0, 1 )
local second_item_take = reaper.GetActiveTake( second_item )
if not first_item_take or reaper.TakeIsMIDI( first_item_take ) or not second_item_take or
  reaper.TakeIsMIDI( second_item_take ) then
  return reaper.defer(function() end)
end

local first_item_end = reaper.GetMediaItemInfo_Value( first_item, "D_POSITION" ) + 
                 reaper.GetMediaItemInfo_Value( first_item, "D_LENGTH" )
local second_item_start = reaper.GetMediaItemInfo_Value( second_item, "D_POSITION" )
local middle = (first_item_end + second_item_start ) / 2
local arrangeview = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000 )
local _, left, _, right = reaper.JS_Window_GetClientRect( arrangeview )
local start_time = reaper.GetSet_ArrangeView2( 0, false, left, right )
local zoom = reaper.GetHZoomLevel()
local screen_pos = math.floor(((middle - start_time) * zoom - reaper.JS_Window_ScreenToClient( arrangeview, 0, 0 ))+0.5)
local x, y = reaper.GetMousePosition()
local move_right = x <= screen_pos

local wanted_item_take = move_right and first_item_take or second_item_take
local wanted_item = move_right and first_item or second_item

local offset = reaper.GetMediaItemTakeInfo_Value( wanted_item_take, "D_STARTOFFS" )

local show
if reaper.GetToggleCommandState( 41827 ) == 0 then
  reaper.Main_OnCommand(41827, 0) -- Show crossfade editor window
  show = true
end

local retval, list = reaper.JS_Window_ListFind( reaper.LocalizeString( "Crossfade Editor", "DLG_540", 0 ), false )
if retval == 0 then return reaper.defer(function() end) end

for address in list:gmatch("[^,]+") do
  local hwnd = reaper.JS_Window_HandleFromAddress( address )
  if reaper.JS_Window_GetClassName( hwnd ) == "#32770" then
    -- Edit: Maximize phase alignment by adjusting left item contents
    reaper.JS_Window_OnCommand( hwnd, move_right and 43459 or 43460 )
    if show then
      reaper.Main_OnCommand(41827, 0) -- Show crossfade editor window
    end
    local loop_cnt = 0
    local function wait()
      if loop_cnt < 3 then
        reaper.defer(wait)
      else
        local change = offset - reaper.GetMediaItemTakeInfo_Value( wanted_item_take, "D_STARTOFFS" )
        local source = reaper.GetMediaItemTake_Source( wanted_item_take )
        if reaper.GetMediaItemInfo_Value( wanted_item, "B_LOOPSRC" ) == 1 then
          local src_len = reaper.GetMediaSourceLength( source )
          change = change - src_len * math.floor(change / src_len + 0.5)
        end
        local when = change > 0 and "later" or "earlier"
        local samplerate = reaper.GetMediaSourceSampleRate( source )
        local msg = "Already maximized"
        change = math.abs(change)
        if change >= 1/samplerate then
          local samples = math.floor((change * samplerate * 10 + 0.5 ) / 10)
          msg = string.format("Moved %.1f ms (%i spls) %s",(change*10000+0.5)/10,samples,when)
        end
        reaper.TrackCtl_SetToolTip( msg, x, y, true )
        return
      end
      loop_cnt = loop_cnt + 1
    end
    reaper.defer(wait)
    return
  end
end

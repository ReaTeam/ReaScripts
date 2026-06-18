-- @description Phase align two selected items by moving one item's contents (choose item from menu)
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

local choice = gfx.showmenu("#Move contents of:||Left item|Right item" )
if choice <= 1 then return reaper.defer(function() end)
else
  wanted_item_take = choice == 2 and first_item_take or second_item_take
  wanted_item = choice == 2 and first_item or second_item
end

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
    reaper.JS_Window_OnCommand( hwnd, choice == 2 and 43459 or 43460 )
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
        local x, y = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip( msg, x, y, true )
        return
      end
      loop_cnt = loop_cnt + 1
    end
    reaper.defer(wait)
    return
  end
end

-- @description Calculate difference in LUFS for selected or all FX of focused FX chain
-- @author amagalma
-- @version 1.01
-- @changelog
--   - Fix for tracks FX chain
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Calculates the volume difference that the selected FX (or all FX, if none selected) will bring, using dry runs (no files are created). The opposite value of the level difference is copied to the clipboard.
--
--   - The correct dry run action will be smartly chosen
--   - Time Selection is taken into account
--   - An FX chain must be visible
--   - Show detailed report
--   - JS_ReaScriptAPI is required


-- Check if JS_ReaScriptAPI is installed
if not reaper.APIExists("JS_Window_ListFind") then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "JS_ReaScriptAPI Installation", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then
    reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else
    reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end


-- FUNCTIONS --------------------------------

local rep, format = string.rep, string.format


local function al(str,cnt)
  return rep(" ", cnt-#str )
end


local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  if num >= 0 then return math.floor(num * mult + 0.5) / mult
  else return math.ceil(num * mult - 0.5) / mult end
end


local function GetInfo()
  local focus, ret_track, ret_item, fxid = reaper.GetFocusedFX2()
  if focus == 0 then
    local number, window_list = reaper.JS_Window_ListFind("FX: ", false)
    if number == 0 then
      return
    else
      -- Hack
      for address in window_list:gmatch("[^,]+") do
        local FX_win = reaper.JS_Window_HandleFromAddress(address)
        local title = reaper.JS_Window_GetTitle(FX_win)
        if (title:match("FX: Track ") or title == "FX: Master Track" or title:match("FX: Item")) and
        reaper.JS_Window_GetParent( FX_win ) == reaper.GetMainHwnd() then
          local x, y = reaper.GetMousePosition()
          local _, left, top = reaper.JS_Window_GetRect( FX_win )
          reaper.JS_Mouse_SetPosition( left+5, top+5 )
          reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_MOUSE_L_CLICK'), 0)
          reaper.JS_Mouse_SetPosition( x, y )
          focus, ret_track, ret_item, fxid = reaper.GetFocusedFX2()
          break
        end
      end
    end
  end
  if focus == 0 then return end
  local sel_FX = {}
  local chain = reaper.CF_GetFocusedFXChain()
  if chain then
    reaper.JS_Window_SetFocus( chain )
    -- Get Selected FX
    local list = reaper.JS_Window_FindChildByID(chain, 1076)
    local _, sel_fx = reaper.JS_ListView_ListAllSelItems(list)
    local a = 0
    for i in sel_fx:gmatch("%d+") do
      sel_FX[a+1] = tonumber(i)
      a = a + 1
    end
  end
  local track = reaper.CSurf_TrackFromID( ret_track, false ) 
  if ret_item ~= -1 then
    local item = reaper.GetTrackMediaItem( track, ret_item )
    local take = reaper.GetMediaItemTake( item, fxid >> 16 )
    if #sel_FX == 0 then
      for i = 0, reaper.TakeFX_GetCount( take )-1 do
        sel_FX[i+1] = i
      end
    end
    return "take", {item = item, take = take}, sel_FX
  else
    if reaper.GetMediaTrackInfo_Value( track, "I_FXEN") ~= 0 then
      if #sel_FX == 0 then
        for i = 0, reaper.TrackFX_GetCount( track )-1 do
          sel_FX[i+1] = i
        end
      end
      return ret_track == 0 and "master" or "track", track, sel_FX
    end
  end
end


local function ToggleFX( what, object, sel_FX )
  if what == "take" then
    for fx = 1, #sel_FX do
      reaper.TakeFX_SetEnabled( object.take, sel_FX[fx], not reaper.TakeFX_GetEnabled( object.take, sel_FX[fx] ) )
    end
  else
    for fx = 1, #sel_FX do
      reaper.TrackFX_SetEnabled( object, sel_FX[fx], not reaper.TrackFX_GetEnabled( object, sel_FX[fx] ) )
    end
  end
end


local function GetStats( what, object, sel_FX )
  -- Get stats with FX
  local DryAction
  if what == "take" then
    DryAction = 42437 -- Calculate loudness of selected items, including take and track FX and settings
  elseif what == "master" then
    DryAction = 42441 -- Calculate loudness of master mix within time selection
  else
    DryAction = 42439 -- Calculate loudness of selected tracks within time selection
  end
   ok1, fx_stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", tostring(DryAction), false)
  if ok1 then

    -- Get stats without FX
    ToggleFX( what, object, sel_FX )
    local ok2, pre_stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", tostring(DryAction), false)
    ToggleFX( what, object, sel_FX )

    if ok2 then
      local name
      local fx_table, LUFSdif = {}, 0
      for a,b in fx_stats:gmatch("(%u-):([^;]+)") do
        if a ~= "FILE" then
          fx_table[a] = tonumber(b)
        end
      end
      if not fx_table.CLIP then fx_table.CLIP = 0 end
      local pre_table = {}
      for a,b in pre_stats:gmatch("(%u-):([^;]+)") do
        if a ~= "FILE" then
          pre_table[a] = tonumber(b)
        end
      end
      if not pre_table.CLIP then pre_table.CLIP = 0 end
      local show = {}
      for k,v in pairs( fx_table ) do
        if pre_table[k] then
          local i = k == "CLIP" and "%i" or "%.2f"
          local dif = v - pre_table[k] or 0
          local d = dif == 0 and "(no difference)" or format("(dif: %.2f)", dif)
          local pos = v >= 0
          local sp = pos and " " or ""
          local a = format( "%s:%s"..i, k, al(k, pos and 9 or 8), pre_table[k] )
          local b = format( i, v )
          show[#show+1] = format( "%s%s===>    %s%s%s%s\n",
                          a, al(a,20), sp, b, al(b, pos and 9 or 10), d ) 
          if k == "LUFSI" then
            LUFSdif = round( dif, 2 )
            reaper.CF_SetClipboard( -LUFSdif )
          end
        end
      end
      table.sort(show, function(a,b) return a<b end)
      show[#show+1] = "\nDifference in LUFS-I is " .. LUFSdif .. " dB (opposite value copied to clipboard)\n\n"
      local title = format( "Action used: '%s'", (reaper.CF_GetCommandText( 0, DryAction )):gsub(
                    ",?%s?via dry run render", "" ))
      table.insert( show, 1, format( "\n%s\n%s\n", title, rep("-", #title) ) )
      reaper.ClearConsole()
      reaper.ShowConsoleMsg( table.concat(show) )
    end
  end
end


-- MAIN --------------------------------------------------------------------

local what, object, sel_FX = GetInfo()

if not what or fx_cnt == 0 then
  return reaper.defer(function() end)
elseif what == "take" then
  reaper.PreventUIRefresh( 1 )
  local sel_items, it_cnt = {}, 0
  for i = reaper.CountSelectedMediaItems( 0 )-1, 0, -1 do
    it_cnt = it_cnt + 1
    sel_items[it_cnt] = reaper.GetSelectedMediaItem( 0, i )
    reaper.SetMediaItemSelected( sel_items[it_cnt], false )
  end
  reaper.SetMediaItemSelected( object.item, true )
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
  GetStats( what, object, sel_FX )
  reaper.PreventUIRefresh( 1 )
  reaper.SetMediaItemSelected( object.item, false )
  for i = 1, #sel_items do
    reaper.SetMediaItemSelected( sel_items[i], true )
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
else
  reaper.PreventUIRefresh( 1 )
  local sel_tracks, tr_cnt = {}, 0
  for i = reaper.CountSelectedTracks( 0 )-1, 0, -1 do
    tr_cnt = tr_cnt + 1
    sel_tracks[tr_cnt] = reaper.GetSelectedTrack( 0, i )
    reaper.SetTrackSelected( sel_tracks[tr_cnt], false )
  end
  reaper.SetTrackSelected( object, true )
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
  GetStats( what, object, sel_FX )
  reaper.PreventUIRefresh( 1 )
  reaper.SetTrackSelected( object, false )
  for i = 1, #sel_tracks do
    reaper.SetTrackSelected( sel_tracks[i], true )
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
end

reaper.defer(function() end)

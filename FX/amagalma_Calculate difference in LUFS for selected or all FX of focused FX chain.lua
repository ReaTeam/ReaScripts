-- @description Calculate difference in LUFS for selected or all FX of focused FX chain
-- @author amagalma
-- @version 2.00
-- @changelog
--   - Complete re-write in order to support containers
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Calculates the volume difference that the selected FX (or all the FX, if none is selected) will bring, using dry runs (no files are created). The opposite value of the level difference is copied to the clipboard.
--
--   - The correct dry run action will be smartly chosen
--   - Time Selection is taken into account
--   - An FX chain must be visible
--   - Shows detailed report
--   - JS_ReaScriptAPI and SWS Extensions are required

local retval, track, item, take, fx, parm = reaper.GetTouchedOrFocusedFX(1)
if not retval then return end

local track = track ~= -1 and reaper.GetTrack(0, track) or reaper.GetMasterTrack(0)
local item = item ~= -1 and reaper.GetMediaItem( 0, item )
local take = (item and take ~= -1) and reaper.GetTake( item, take )

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

local function get_container_path_from_fx_id( ptr, fxidx ) -- modified Justin's function
  -- returns a list of 1-based IDs
  if fxidx & 0x2000000 then
    local is_take = reaper.ValidatePtr( ptr, "MediaItem_Take*" )
    local FX_GetCount = is_take and reaper.TakeFX_GetCount or reaper.TrackFX_GetCount
    local FX_GetNamedConfigParm = is_take and reaper.TakeFX_GetNamedConfigParm or reaper.TrackFX_GetNamedConfigParm
    local ret, ret_n = { }, 0
    local n = FX_GetCount(ptr)
    local curidx = (fxidx - 0x2000000) % (n+1)
    local remain = math.floor((fxidx - 0x2000000) / (n+1))
    if curidx < 1 then return nil end -- bad address
    local addr, addr_sc = curidx + 0x2000000, n + 1
    while true do
      local ccok, cc = FX_GetNamedConfigParm(ptr, addr, 'container_count')
      if not ccok then return nil end -- not a container
      ret_n = ret_n + 1
      ret[ret_n] = curidx
      n = tonumber(cc)
      if remain <= n then 
        if remain > 0 then
          ret_n = ret_n + 1
          ret[ret_n] = remain
        end
        ret.depth = ret_n
        return ret
      end
      curidx = remain % (n+1)
      remain = math.floor(remain / (n+1))
      if curidx < 1 then return nil end -- bad address
      addr = addr + addr_sc * curidx
      addr_sc = addr_sc * (n+1)
    end
  end
  return { fxid+1 }
end

local function get_fx_id_from_container_path(ptr, idx1, ...) -- returns a fx-address from a list of 1-based IDs
  local is_take = reaper.ValidatePtr( ptr, "MediaItem_Take*" )
  local FX_GetCount = is_take and reaper.TakeFX_GetCount or reaper.TrackFX_GetCount
  local FX_GetNamedConfigParm = is_take and reaper.TakeFX_GetNamedConfigParm or reaper.TrackFX_GetNamedConfigParm
  local sc,rv = FX_GetCount(ptr)+1, 0x2000000 + idx1
  for i,v in ipairs({...}) do
    local ccok, cc = FX_GetNamedConfigParm(ptr, rv, 'container_count')
    if ccok ~= true then return nil end
    rv = rv + sc * v
    sc = sc * (1+tonumber(cc))
  end
  return rv
end

local function getFXListHWND( FXChain_hwnd, CurrentFXDepth )
  local hwnd = FXChain_hwnd
  local d = 1
  while d < CurrentFXDepth do
   d = d + 1
    hwnd = reaper.JS_Window_FindEx( hwnd, hwnd, "#32770", "")
  end
  return reaper.JS_Window_FindChildByID(hwnd, 1076)
end

local function GetSelectedFX( FXList_hwnd ) -- 0-based
  local sel_FX = {}
  local _, sel_fx = reaper.JS_ListView_ListAllSelItems( FXList_hwnd )
  local a = 0
  for i in sel_fx:gmatch("%d+") do
    sel_FX[a+1] = tonumber(i)
    a = a + 1
  end
  if #sel_FX == 0 then
    for i = 0, reaper.JS_ListView_GetItemCount( FXList_hwnd )-1 do
      sel_FX[i+1] = i
    end
  end
  return sel_FX
end

local function ToggleFX( sel_FX, CurrentFXInfo )
  if take then
    for fx = 1, #sel_FX do
      local id = sel_FX[fx]
      if CurrentFXInfo then 
        CurrentFXInfo[CurrentFXInfo.depth] = sel_FX[fx] + 1 -- make it 1-based for containers
        id = get_fx_id_from_container_path(take, table.unpack(CurrentFXInfo) )
      end
      reaper.TakeFX_SetEnabled( take, id, not reaper.TakeFX_GetEnabled( take, id ) )
    end
  else
    for fx = 1, #sel_FX do
      local id = sel_FX[fx]
      if CurrentFXInfo then 
        CurrentFXInfo[CurrentFXInfo.depth] = sel_FX[fx] + 1 -- make it 1-based for containers
        id = get_fx_id_from_container_path(track, table.unpack(CurrentFXInfo) )
      end
      reaper.TrackFX_SetEnabled( track, id, not reaper.TrackFX_GetEnabled( track, id ) )
    end
  end
end

local function GetStats( sel_FX, CurrentFXInfo )
  -- Get stats with FX
  local DryAction
  if take then
    DryAction = 42437 -- Calculate loudness of selected items, including take and track FX and settings
  elseif track == reaper.GetMasterTrack(0) then
    DryAction = 42441 -- Calculate loudness of master mix within time selection
  else
    DryAction = 42439 -- Calculate loudness of selected tracks within time selection
  end
   local ok1, fx_stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", tostring(DryAction), false)
  if ok1 then

    -- Get stats without FX
    ToggleFX( sel_FX, CurrentFXInfo )
    local ok2, pre_stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", tostring(DryAction), false)
    ToggleFX( sel_FX, CurrentFXInfo )

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

local FXChain_hwnd = take and reaper.CF_GetTakeFXChain( take ) or reaper.CF_GetTrackFXChain( track )
local CurrentFXInfo = get_container_path_from_fx_id(take and take or track, fx)
local FXList_hwnd = getFXListHWND( FXChain_hwnd, CurrentFXInfo and CurrentFXInfo.depth or 1 )
local sel_FX = GetSelectedFX( FXList_hwnd )

if take then
  reaper.PreventUIRefresh( 1 )
  local sel_items, it_cnt = {}, 0
  for i = reaper.CountSelectedMediaItems( 0 )-1, 0, -1 do
    it_cnt = it_cnt + 1
    sel_items[it_cnt] = reaper.GetSelectedMediaItem( 0, i )
    reaper.SetMediaItemSelected( sel_items[it_cnt], false )
  end
  reaper.SetMediaItemSelected( item, true )
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
  GetStats( sel_FX, CurrentFXInfo )
  reaper.PreventUIRefresh( 1 )
  reaper.SetMediaItemSelected( item, false )
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
  reaper.SetTrackSelected( track, true )
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
  GetStats( sel_FX, CurrentFXInfo )
  reaper.PreventUIRefresh( 1 )
  reaper.SetTrackSelected( track, false )
  for i = 1, #sel_tracks do
    reaper.SetTrackSelected( sel_tracks[i], true )
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
end

reaper.defer(function() end)

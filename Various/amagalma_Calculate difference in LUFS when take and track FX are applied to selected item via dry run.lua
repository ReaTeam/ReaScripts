-- @description Calculate difference in LUFS when take and track FX are applied to selected item via dry run
-- @author amagalma
-- @version 1.1
-- @changelog
--   - Show detailed report if no FX to apply.
--   - Fix corner cases that would cause a crash while showing report.
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Calculates the volume difference that take and track FX bring to the selected item using a dry runs (no files are created). The opposite value of the level difference is copied to the clipboard.
--
--   - Show detailed report.
--
--   Works with only one item selected.


local rep, format = string.rep, string.format
local takefx, trackfx = {}, {}
local no_takefx, no_trackfx, take, track


local function al(str,cnt)
  return rep(" ", cnt-#str )
end


local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  if num >= 0 then return math.floor(num * mult + 0.5) / mult
  else return math.ceil(num * mult - 0.5) / mult end
end


local function EnableFX( bool )
  reaper.PreventUIRefresh( 1 )
  if not no_takefx then
    for fx = 1, #takefx do
      reaper.TakeFX_SetEnabled( take, takefx[fx], bool )
    end
  end
  if not no_trackfx then
    for fx = 1, #trackfx do
      reaper.TrackFX_SetEnabled( track, trackfx[fx], bool )
    end
  end
  reaper.PreventUIRefresh( -1 )
end


-- MAIN --

local item_cnt = reaper.CountSelectedMediaItems(0)
if item_cnt == 1 then
  local item = reaper.GetSelectedMediaItem(0,0)
  take = reaper.GetActiveTake( item )
  if take and reaper.TakeIsMIDI( take ) == false then
    if not reaper.CF_GetMediaSourceOnline( reaper.GetMediaItemTake_Source( take ) ) then
      reaper.MB( "Take source is offine.", "Nothing to do!", 0 )
      return reaper.defer(function () end)
    end
    local takefx_cnt = reaper.TakeFX_GetCount( take )
    track = reaper.GetMediaItemTrack( item )
    local trackfx_cnt = reaper.TrackFX_GetCount( track )
    local trackfx_disabled = reaper.GetMediaTrackInfo_Value( track, "I_FXEN") == 0

    -- Count enabled FX
    for fx = 0, takefx_cnt do
      if reaper.TakeFX_GetEnabled( take, fx ) then
        takefx[#takefx+1] = fx
      end
    end
    if not trackfx_disabled then
      for fx = 0, trackfx_cnt do
        if reaper.TrackFX_GetEnabled( track, fx ) then
          trackfx[#trackfx+1] = fx
        end
      end
    end

    -- Exit if not FX to apply
    local exit_msg
    no_takefx = #takefx == 0
    no_trackfx = #trackfx == 0
    if takefx_cnt == 0 and trackfx_cnt == 0 then
      exit_msg = "No Track or Take FX to apply on item."
    else
      if no_takefx and no_trackfx then
        exit_msg = "No Track or Take FX to apply on item.\n\nDetails:\n\n" ..
        ( trackfx_disabled and "- Track FX Chain is bypassed.\n" or
          (no_trackfx and
            (trackfx_cnt ~= 0 and "- All Track FX are disabled.\n" or "")
          or "")
        or "") ..
        (no_takefx and
          (takefx_cnt ~= 0 and "- All Take FX are bypassed." or "")
        or "")
      end
    end
    if exit_msg then
      reaper.MB( exit_msg, "No FX to apply!", 0 )
      return reaper.defer(function () end)
    end

    -- Get stats with FX
    local ok1, fx_stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", "42437", false)
    if ok1 then

      -- Get stats without FX
      EnableFX( false ) -- Disable FX
      local ok2, pre_stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", "42437", false)
      EnableFX( true ) -- Enable FX

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
        show[#show+1] = "\nDifference in LUFS-I is " .. LUFSdif .. " dB (opposite value copied to clipboard)"
        local title = format( "Take name: %s", reaper.GetTakeName( take ) )
        table.insert( show, 1, format( "\n%s\n%s\n", title, rep("-", #title) ) )
        reaper.ShowConsoleMsg( table.concat(show) )
      end
    end
  end
else
  reaper.MB( "Select just one item", "Message", 0 )
end
reaper.defer(function () end) -- No undo point

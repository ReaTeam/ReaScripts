-- @description Calculate difference in LUFS when take and track FX are applied to selected item via dry run
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Calculates the volume difference that take and track FX bring to the selected item using a dry runs (no files are created). The opposite value of the level difference is copied to the clipboard.
--
--   Works with only one item selected.


local rep, format = string.rep, string.format

local function al(str,cnt)
  return rep(" ", cnt-#str )
end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  if num >= 0 then return math.floor(num * mult + 0.5) / mult
  else return math.ceil(num * mult - 0.5) / mult end
end

local item_cnt = reaper.CountSelectedMediaItems(0)
if item_cnt == 1 then
  local takefx, trackfx = {}, {}
  local item = reaper.GetSelectedMediaItem(0,0)
  local take = reaper.GetActiveTake( item )
  if take and reaper.TakeIsMIDI( take ) == false then
    local takefx_cnt = reaper.TakeFX_GetCount( take )
    local track = reaper.GetMediaItemTrack( item )
    local trackfx_cnt = reaper.TrackFX_GetCount( track )
    if takefx_cnt == 0 and trackfx_cnt == 0 then
      reaper.MB( "No Track or Take FX to apply on item.", "No FX to apply!", 0 )
      return reaper.defer(function () end)
    end
    -- Get stats with FX
    local ok1, fx_stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", "42437", false)
    if ok1 then
      -- Disable FX
      reaper.PreventUIRefresh( 1 )
      for fx = 0, takefx_cnt do
        if reaper.TakeFX_GetEnabled( take, fx ) then
          takefx[#takefx+1] = fx
          reaper.TakeFX_SetEnabled( take, fx, false )
        end
      end
      for fx = 0, trackfx_cnt do
        if reaper.TrackFX_GetEnabled( track, fx ) then
          trackfx[#trackfx+1] = fx
          reaper.TrackFX_SetEnabled( track, fx, false )
        end
      end
      reaper.PreventUIRefresh( -1 )
      -- Get stats without FX
      local ok2, pre_stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", "42437", false)
      reaper.PreventUIRefresh( 1 )
      -- Enable FX
      for fx = 1, #takefx do
        reaper.TakeFX_SetEnabled( take, takefx[fx], true )
      end
      for fx = 1, #trackfx do
        reaper.TrackFX_SetEnabled( track, trackfx[fx], true )
      end
      reaper.PreventUIRefresh( -1 )
      if ok2 then
        local name
        local fx_table, LUFSdif = {}
        for a,b in fx_stats:gmatch("(%u-):([^;]+)") do
          if a ~= "FILE" then
            fx_table[a] = tonumber(b)
          end
        end
        local pre_table = {}
        for a,b in pre_stats:gmatch("(%u-):([^;]+)") do
          if a ~= "FILE" then
            pre_table[a] = tonumber(b)
          end
        end
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

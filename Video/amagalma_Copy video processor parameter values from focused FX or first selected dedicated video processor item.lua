-- @description Copy video processor parameter values from focused FX or first selected dedicated video processor item
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma


local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX( 1 )
local parameters = {}

if retval then

  local track = reaper.GetTrack( 0, trackidx )

  if takeidx == -1 then -- track FX
    local _, fx_ident = reaper.TrackFX_GetNamedConfigParm( track, fxidx, "fx_ident" )
    if fx_ident ~= "__builtin_video_processor" then
      reaper.MB("The focused FX is not a video processor.", "Nothing copied!", 0)
      return
    else
      for p = 0, reaper.TrackFX_GetNumParams( track, fxidx )-4 do -- -4 to not copy wet, bypass etc
        local cur_val = reaper.TrackFX_GetParam( track, fxidx, p )
        local _, param_name = reaper.TrackFX_GetParamName( track, fxidx, p )
        parameters[p+1] = param_name .. ":" .. cur_val
      end
    end
  else -- ItemFX
    local take = reaper.GetTake( reaper.GetTrackMediaItem( track, itemidx ), takeidx )
    local _, fx_ident = reaper.TakeFX_GetNamedConfigParm( take, fxidx, "fx_ident" )
    if fx_ident ~= "__builtin_video_processor" then
      reaper.MB("The focused FX is not a video processor.", "Nothing copied!", 0)
      return
    else
      for p = 0, reaper.TakeFX_GetNumParams( take, fxidx )-4 do
        local cur_val = reaper.TakeFX_GetParam( take, fxidx, p )
        local _, param_name = reaper.TakeFX_GetParamName( take, fxidx, p )
        parameters[p+1] = param_name .. ":" .. cur_val
      end
    end
  end

else -- try item

  local sel_item = reaper.GetSelectedMediaItem( 0, 0 )
  local sel_item_take = reaper.GetActiveTake( sel_item )
  local source = sel_item_take and reaper.GetMediaItemTake_Source( sel_item_take )
  local source_type = source and reaper.GetMediaSourceType( source )
  if not source_type or source_type ~= "VIDEOEFFECT" then
    reaper.MB("There is not any focused FX or any video processor item selected!", "Nothing copied!", 0)
    return
  else -- work with item chunk
    local last_param
    local _, chunk = reaper.GetItemStateChunk( sel_item, "", false )
    for line in chunk:gmatch("[^\n\r]+") do
      param, param_name = line:match("|//@param(%d+):[^']+'([^']+)")
      if param and param_name then
        last_param = tonumber(param)
        parameters[last_param] = param_name
      elseif line:match("CODEPARM ") then
        line = line:sub(10)
        local cnt = 0
        last_param = last_param + 1
        for val in line:gmatch("%S+") do
          cnt = cnt + 1
          if cnt == last_param then break end
          if parameters[cnt] then
            parameters[cnt] = parameters[cnt] .. ":" .. val
          else
            parameters[cnt] = "param" .. tostring(cnt) .. ":0"
          end
        end
      end
    end
  end
end

if #parameters > 0 then
  reaper.SetExtState( "amagalma_copyVideoParameterValues", "values", table.concat(parameters, "|"), false )
  local x, y = reaper.GetMousePosition()
  reaper.TrackCtl_SetToolTip( "Copied video parameter values", x, y, true )
end
reaper.defer( function() end )

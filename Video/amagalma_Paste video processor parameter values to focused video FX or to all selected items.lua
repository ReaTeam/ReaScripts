-- @description Paste video processor parameter values to focused video FX or to all selected items
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma


local ext_state = reaper.GetExtState( "amagalma_copyVideoParameterValues", "values" )
if ext_state == "" then
  reaper.MB( "You haven't copied any video processor parameter values.", "Nothing done!", 0 )
  return
end

local saved, saved_cnt = {}, 0
for entry in ext_state:gmatch("[^|]+") do
  local name, value = entry:match("([^:]+):([^:]+)")
  saved_cnt = saved_cnt + 1
  saved[saved_cnt] = { name = name, val = tonumber(value) }
end

--------

local x, y = reaper.GetMousePosition()
local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX( 1 )

if retval then -- work with focused fx_chain
  local track = reaper.GetTrack( 0, trackidx )
  if takeidx == -1 then -- track FX

    local _, fx_ident = reaper.TrackFX_GetNamedConfigParm( track, fxidx, "fx_ident" )
    if fx_ident ~= "__builtin_video_processor" then
      reaper.MB("The focused FX is not a video processor.", "Nothing done", 0)
      return
    else
      local num_param = reaper.TrackFX_GetNumParams( track, fxidx )-3
      if num_param ~= saved_cnt then
        reaper.MB("The focused video FX has a different number of\nparameters than the one that was copied.", "Nothing done", 0)
        return
      else
        for p = 1, num_param do
          local _, param_name = reaper.TrackFX_GetParamName( track, fxidx, p-1 )
          if param_name ~= saved[p].name then
            reaper.MB("The focused video FX has a different named parameters\nthan the one that was copied.", "Nothing done", 0)
            return
          end
          reaper.Undo_BeginBlock()
          reaper.PreventUIRefresh( 1 )
          for p = 0, num_param-1 do
            reaper.TrackFX_SetParam( track, fxidx, p, saved[p+1].val )
          end
          reaper.PreventUIRefresh( -1 )
          reaper.Undo_EndBlock( "Changed video parameter values", 2 )
          reaper.TrackCtl_SetToolTip( "Pasted values to focused track FX", x, y, true )
          return
        end
      end
    end
  else -- ItemFX
    local item = reaper.GetTrackMediaItem( track, itemidx )
    local take = reaper.GetTake( item, takeidx )
    local _, fx_ident = reaper.TakeFX_GetNamedConfigParm( take, fxidx, "fx_ident" )
    if fx_ident ~= "__builtin_video_processor" then
      reaper.MB("The focused FX is not a video processor.", "Nothing done", 0)
      return
    else
      local num_param = reaper.TakeFX_GetNumParams( take, fxidx )-3
      if num_param ~= saved_cnt then
        reaper.MB("The focused video FX has a different number of\nparameters than the one that was copied.", "Nothing done", 0)
        return
      else
        for p = 1, num_param do
          local _, param_name = reaper.TakeFX_GetParamName( take, fxidx, p-1 )
          if param_name ~= saved[p].name then
            reaper.MB("The focused video FX has a different named parameters\nthan the one that was copied.", "Nothing done", 0)
            return
          end
          reaper.PreventUIRefresh( 1 )
          for p = 0, num_param-1 do
            reaper.TakeFX_SetParam( take, fxidx, p, saved[p+1].val )
          end
          reaper.PreventUIRefresh( -1 )
          reaper.Undo_OnStateChange_Item( 0, "Changed video parameter values", item )
          reaper.TrackCtl_SetToolTip( "Pasted values to focused take FX", x, y, true )
          return
        end
      end
    end
  end
else -- work with selected items
  local item_cnt = reaper.CountSelectedMediaItems( 0 )
  if item_cnt == 0  then
    reaper.MB("No items selected!", "Nothing done", 0)
    return
  end
  local to_process, to_process_cnt = {}, 0
  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    local take = reaper.GetActiveTake( item )
    if take then
      for fx = 0, reaper.TakeFX_GetCount( take )-1 do
        local _, fx_ident = reaper.TakeFX_GetNamedConfigParm( take, fx, "fx_ident" )
        if fx_ident == "__builtin_video_processor" then
          local num_param = reaper.TakeFX_GetNumParams( take, fx )-3
          local same_parm_names = true
          if num_param == saved_cnt then
            for p = 1, num_param do
              local _, param_name = reaper.TakeFX_GetParamName( take, fx, p-1 )
              if param_name ~= saved[p].name then
                same_parm_names = false
                break
              end
            end
          else
            same_parm_names = false
          end
          if same_parm_names then
            to_process_cnt = to_process_cnt + 1
            to_process[to_process_cnt] = { take = take, fxid = fx }
          end
        end
      end
      -- check if dedicated processor
      local source = reaper.GetMediaItemTake_Source( take )
      local source_type = reaper.GetMediaSourceType( source )
      if source_type == "VIDEOEFFECT" then
        local parameters, last_param = {}
        local _, chunk = reaper.GetItemStateChunk( item, "", false )
        local start_noting = false
        local same_parm_names = true
        for line in chunk:gmatch("[^\n\r]+") do
          if line == "<SOURCE VIDEOEFFECT\n" then
            start_noting = true
          end
          if start_noting then
            param, param_name = line:match("|//@param(%d+):[^']+'([^']+)")
            reaper.ShowConsoleMsg(param_name .. "\n")
            if param and param_name then
              last_param = tonumber(param)
              if param_name ~= saved[param].name then
                same_parm_names = false
                break
              end
            elseif line:match("CODEPARM ") then
              start_noting = false
              break
            end
          end
        end
        if same_parm_names then
          to_process_cnt = to_process_cnt + 1
          to_process[to_process_cnt] = { take = item, fxid = chunk } -- .take contains item, fxid contains chunk!
        end
      end
    end
  end
  if to_process_cnt == 0 then
    reaper.MB("No suitable video processor FX on the selected items!", "Nothing done", 0)
    return
  else
    reaper.PreventUIRefresh( 1 )
    for i = 1, to_process_cnt do
      if tonumber(to_process[i].fxid) then
        for p = 0, saved_cnt-1 do
          reaper.TakeFX_SetParam( to_process[i].take, to_process[i].fxid, p, saved[p+1].val )
        end
      else -- work with chunk
        local codeparm = "CODEPARM"
        for i = 1, saved_cnt do
          codeparm = codeparm .. " " .. tostring(saved[i].val)
        end
        local chunk = to_process[i].fxid:gsub("CODEPARM[^n]-", codeparm, 1)
        reaper.SetItemStateChunk( to_process[i].take, chunk, false )
      end
    end
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_OnStateChange( "Changed video parameter values" )
    reaper.TrackCtl_SetToolTip( "Pasted values to " .. tostring(to_process_cnt) .. " FX instances", x, y, true )
  end
end

-- @description Set envelope in time selection or segment under mouse to 0 dB or center
-- @author AZ
-- @version 1.0
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @donation Donate via PayPal https://paypal.me/AZsound
-- @about For feature requests and bug reports click website button below.


DEBUG = false
--ExtStateName = 'SetEnvToZeroOr50Perc_AZ'

function msg(value)
  if DEBUG then reaper.ShowConsoleMsg(tostring(value)..'\n') end
end


-----------------------------------------

function ExtractDefPointShape(env)
  local ret, chunk = reaper.GetEnvelopeStateChunk(env, '', false)
  for line in chunk:gmatch("[^\n]+") do
    if line:match('DEFSHAPE') then
      local value = line:match('%d')
      return value
    end
  end
end

-----------------------------------------

function SetSegmentToValue(env, value, timeShift ,takeRate)
  local pos = reaper.BR_PositionAtMouseCursor(false)
  pos = (pos - timeShift) * takeRate
  local point = reaper.GetEnvelopePointByTimeEx( env, -1, pos )
  reaper.SetEnvelopePointEx( env, -1, point, nil, value, nil, nil, nil, false )
  reaper.SetEnvelopePointEx( env, -1, point+1, nil, value, nil, nil, nil, false ) -- next point
  return true
end

function SetTSvalue(env, start_time, end_time, value, timeShift, takeRate)
    if not env then return end
    
    local aiIdx = -1
    local start_time = (start_time - timeShift) * takeRate
    local end_time = (end_time - timeShift) * takeRate
    
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    -- Get current values at edges 
    local _, val_start = reaper.Envelope_Evaluate(env, start_time, 0, 0) 
    local _, val_end = reaper.Envelope_Evaluate(env, end_time, 0, 0)
    
    local pShape = tonumber(ExtractDefPointShape(env))
    local retEnv, trans = reaper.get_config_var_string('envtranstime')
    if retEnv then trans = tonumber(trans) else trans = 0.0001 end

    -- Delete existing points inside
    reaper.DeleteEnvelopePointRange(env, start_time + 0.0001, end_time - 0.0001)
    reaper.Envelope_SortPoints(env)
    
    local testInP = reaper.GetEnvelopePointByTimeEx( env, aiIdx, start_time )
    --local testOutP = reaper.GetEnvelopePointByTimeEx( env, aiIdx, end_time )
    local testTimeIn, testTimeOut = 0,0
    
    if testInP then
      local ret, time, val, shape, tens, sel = reaper.GetEnvelopePointEx(env, aiIdx, testInP )
      testTimeIn = time
    end
    if testOutP then
      local ret, time, val, shape, tens, sel = reaper.GetEnvelopePointEx(env, aiIdx, testInP+1 )
      testTimeOut = time
    end

    -- Add 4 points:
    -- 1) before selection (to keep original)
    if start_time - testTimeIn > trans then
      reaper.InsertEnvelopePoint(env, start_time, val_start, 0, 0, false, true)
    end
    -- 2) start of selection (set to 0.5)
    reaper.InsertEnvelopePoint(env, start_time + trans, value, 0, 0, false, true)
    -- 3) end of selection (still 0.5)
    reaper.InsertEnvelopePoint(env, end_time - trans, value, 0, 0, false, true)
    -- 4) after selection (restore original)
    if testTimeOut - end_time > trans or testTimeIn >= testTimeOut then
      reaper.InsertEnvelopePoint(env, end_time, val_end, 0, 0, false, true)
    end
    
    reaper.Envelope_SortPoints(env)
    
    return true
end

function GetValue(env)
  if not env then return end
  
  local _, name = reaper.GetEnvelopeName( env )
  local value
  if string.find(name, "Volume") then
    value = reaper.GetEnvelopeScalingMode( env ) == 1 and 716.21785031263 or 1
  else
    local br_env = reaper.BR_EnvAlloc( env, true )
    value = ({reaper.BR_EnvGetProperties( br_env )})[9]
    reaper.BR_EnvFree( br_env, false )
  end
  
  return value
end

function main()
  TSstart, TSend = reaper.GetSet_LoopTimeRange2(0,false,false,0,0,false)
  ArrStart, ArrEnd = reaper.GetSet_ArrangeView2(0,false,0,0,0,0)
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  local RazorEdits
  local env, mouseEnv, isTake
  local timeShift = 0
  local takeRate = 1
  
  if RazorEdits then
  
  end
  
  local x,y = reaper.GetMousePosition()
  local track, info = reaper.GetThingFromPoint(x, y)
  --reaper.GetTrackEnvelope(track, info:match('%d+'))
  mouseEnv, isTake = reaper.BR_GetMouseCursorContext_Envelope()
  
  if mouseEnv then 
    env = mouseEnv
  else
    env = reaper.GetSelectedEnvelope(0)
  end
  
  if not env then return end
  
  local envTake, index, index2 = reaper.Envelope_GetParentTake( env )
  if envTake then
    local item = reaper.GetMediaItemTake_Item(envTake) 
    timeShift = reaper.GetMediaItemInfo_Value(item, 'D_POSITION') 
    takeRate = reaper.GetMediaItemTakeInfo_Value(envTake, 'D_PLAYRATE')
  end
  
  if env and TSstart ~= TSend and (TSend > ArrStart or TSstart < ArrEnd) then
    local value = GetValue(env)
    if SetTSvalue(env, TSstart, TSend, value, timeShift, takeRate) then
      return 'Set envelope in TS to 0 or 50%'
    end
  elseif mouseEnv then
    local value = GetValue(mouseEnv)
    if SetSegmentToValue(mouseEnv, value, timeShift, takeRate) then
      return 'Set envelope segment to 0 or 50%'
    end
  end
  
  
end

function start()
  if reaper.APIExists( 'BR_GetMouseCursorContext' ) ~= true then
    reaper.ShowMessageBox('Please, install SWS extension!', 'No SWS extension', 0)
    return
  end
  
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  
  UndoString = main()
  
  if UndoString then --msg(UndoString)
    reaper.Undo_EndBlock2( 0, UndoString, -1 )
    reaper.UpdateArrange()
  else reaper.defer(function()end)
  end  
end

start()

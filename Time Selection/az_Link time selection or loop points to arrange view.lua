-- @description Link time selection or loop points to arrange view
-- @author AZ
-- @version 1.2
-- @changelog - Fixed edit cursor lost outside of time selection on scrolling
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   # Link time selection or loop points to arrange view
--
--   Useful for looping visible arrange area while editing.
--
--   Set this script in autorun section to preserve it's ON state.

Options = {}
Options.SnapToGrid = true
Options.snapCoeff = 5
--------------------
--------------------
function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

---------------------------------

function main()

  local state = tonumber(reaper.GetExtState(ExtStateName, 'state'))
  if state>0 then

    local start_time, end_time = reaper.GetSet_ArrangeView2( 0, false, 0, 0, 0, 0 )
    local arrange_length = end_time - start_time
    local startTS = start_time + arrange_length/20
    local endTS = end_time - arrange_length/20
    local prjStartCoeff
    
    if start_time <= startTS/2 then
      prjStartCoeff = start_time / (startTS - start_time)
    else
      prjStartCoeff = 1
    end
    
    startTS = (start_time + arrange_length/20) * prjStartCoeff
    
    if Options.SnapToGrid == true then
      snapCoeff = Options.snapCoeff
      startTSgrid = reaper.SnapToGrid(0, startTS)
      endTSgrid = reaper.SnapToGrid(0, endTS)
      
      if startTSgrid <= start_time or startTSgrid-start_time > arrange_length/snapCoeff then
        startTSgrid = startTS
      end
      
      if endTSgrid >= end_time or end_time-endTSgrid > arrange_length/snapCoeff then
       endTSgrid = endTS
      end

    end
    
    local _, _ = reaper.GetSet_LoopTimeRange2( 0, true, true, startTSgrid, endTSgrid, false )
    
    local playState = reaper.GetPlayStateEx(0)
    local curPos = reaper.GetCursorPosition()

    if oldTSstart ~= startTSgrid then
      
      if curPos < startTSgrid or curPos > endTSgrid then
        local contScroll = reaper.GetToggleCommandState(41817)* -1 +1
        reaper.SetEditCurPos2(0,startTSgrid,false, contScroll)
      end
    end
    
    oldTSstart = startTSgrid
    reaper.defer(main)
  else return end
end

--------------------------------

-------------Start--------------
ExtStateName = 'LinkTStoArrange'

local state = reaper.GetExtState(ExtStateName, 'state')

if state ~= '' then
  local _,_,secID,cmdID = reaper.get_action_context()
  local realstate =  reaper.GetToggleCommandStateEx(secID, cmdID)
  if realstate == tonumber(state) then 
    state = -tonumber(state) +1
  else state = tonumber(state)
  end
else
  state = 1
end
reaper.SetExtState(ExtStateName, 'state', state, true)

local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
if state > 0 then --work
  reaper.SetToggleCommandState( sec, cmd, state )
  reaper.RefreshToolbar2( sec, cmd )
  main()

else
  reaper.SetToggleCommandState( sec, cmd, state )
  reaper.RefreshToolbar2( sec, cmd )
  reaper.defer(function()end)
end


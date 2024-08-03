-- @description Auto-send all inputs to the virtual midi keyboard (VKB) if mouse is in empty track space or recording is running (Background)
-- @author AZ
-- @version 1.0
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   # Auto-send all inputs to the virtual midi keyboard (VKB) if mouse is in empty track space or recording is running (Background)
--
--   The script is useful to release keyboard for the editing shortcuts in arrange while you use virtual midi keyboard.
--   So you can use one-button shortcuts when mouse cursor placed on items or envelopes.
--   Move mouse to the empty track space and you are ready to use computer keyboard for the virtual midi keyboard.
--
--   Place this script into startup section and forget about extra toggling. (look for SWS startup action as example)
--
--   Choose Terminate and save if it asks on first closing the script.

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end
------------------
-------------------
function GetTopBottomItemHalf()
local itempart
local x, y = reaper.GetMousePosition()

local item_under_mouse = reaper.GetItemFromPoint(x,y,true)

if item_under_mouse then

  local item_h = reaper.GetMediaItemInfo_Value( item_under_mouse, "I_LASTH" )
  
  local OScoeff = 1
  if reaper.GetOS():match("^Win") == nil then
    OScoeff = -1
  end
  
  local test_point = math.floor( y + (item_h-1) *OScoeff)
  local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
  
  if item_under_mouse == test_item then
    itempart = "header"
  else
    local test_point = math.floor( y + item_h/2 *OScoeff)
    local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
    
    if item_under_mouse ~= test_item then
      itempart = "bottom"
    else
      itempart = "top"
    end
  end

  return item_under_mouse, itempart
else return nil end

end
-----------------
-----------------
function main()
  local kb_state = reaper.GetToggleCommandState(40377)  --View: Show virtual MIDI keyboard
  if kb_state == 1 then
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local inp_state = reaper.GetToggleCommandState(40637) --Virtual MIDI keyboard: Send all input to VKB
    local playstate = reaper.GetPlayStateEx(0)
    local item, part = GetTopBottomItemHalf()
    
    if window ~= 'arrange'
    --or ((not item or part == 'header') and segment ~= 'envelope')
    or (not item and segment ~= 'envelope')
    or playstate  == 5 then
      if inp_state == 0 then reaper.Main_OnCommandEx(40637,0,0) end --Toggle ON
    else
      if inp_state == 1 then reaper.Main_OnCommandEx(40637,0,0) end --Toggle OFF
    end
    
  end
  reaper.defer(main)
end
-----------------
-----------------
ExtStateName = 'autoToggleVKBinputs_AZ'

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

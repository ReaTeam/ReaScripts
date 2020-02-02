-- @description amagalma_Set envelope segment under mouse cursor to 0 dB or center
-- @author amagalma
-- @version 1.0
-- @about
--   # Resets the envelope segment under the mouse cursor to 0 dB for Volume, or to the center for all other envelopes
--   - Recommended to be used as an Envelope segment mouse modifier for double click
--   - Undo point is created if needed and is named accordingly
--   - Needs SWS Extensions

local reaper = reaper

local window, segment, details = reaper.BR_GetMouseCursorContext()
local env, istakeEnvelope = reaper.BR_GetMouseCursorContext_Envelope()
--reaper.ShowConsoleMsg(string.format("%s %s %s %s %s\n", window, segment, details, env, istakeEnvelope))
if details == "env_segment" or env then
  local _, name = reaper.GetEnvelopeName( env )
  local value
  if string.find(name, "Volume") then
    value = reaper.GetEnvelopeScalingMode( env ) == 1 and 716.21785031263 or 1
  else
    local br_env = reaper.BR_EnvAlloc( env, true )
    value = ({reaper.BR_EnvGetProperties( br_env )})[9]
    reaper.BR_EnvFree( br_env, false )
  end
  local pos = reaper.BR_GetMouseCursorContext_Position()
  local point = reaper.GetEnvelopePointByTimeEx( env, -1, pos )
  --reaper.ShowConsoleMsg(tostring( point) .. " \n")
  reaper.SetEnvelopePointEx( env, -1, point, nil, value, nil, nil, nil, false )
  reaper.SetEnvelopePointEx( env, -1, point+1, nil, value, nil, nil, nil, false ) -- next point
  if istakeEnvelope then
    reaper.Undo_OnStateChangeEx( "Reset take envelope segment to 0 dB", 1, -1 )
  else -- track envelope
    -- click is needed to update the ECP
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_MOUSE_L_CLICK'), 0) -- SWS/S&M: Left mouse click at cursor position (use w/o modifier)
    reaper.Undo_OnStateChangeEx( "Reset track envelope segment to 0 dB", 1, -1 )
  end
else
  return
end

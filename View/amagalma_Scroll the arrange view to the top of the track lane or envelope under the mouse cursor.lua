-- @description Scroll the arrange view to the top of the track lane or envelope under the mouse cursor
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma

if not reaper.CF_SetTcpScroll then
  return reaper.MB( "Please, install / update SWS.", "Missing CF_SetTcpScroll API", 0 )
end

local x, y = reaper.GetMousePosition()
local track, info = reaper.GetTrackFromPoint( x, y )

if not track then return end

local function Info( str )
  return reaper.GetMediaTrackInfo_Value( track, str )
end

local position = 0

if info == 1 then
  reaper.BR_GetMouseCursorContext()
  local env, isTakeEnvelope = reaper.BR_GetMouseCursorContext_Envelope()
  if not isTakeEnvelope then
    position = reaper.GetEnvelopeInfo_Value( env, "I_TCPY_USED" )
  end
else
  local lane = info >> 8
  if lane > 0 and Info("C_LANESCOLLAPSED") == 0 then
    position = ( ( Info("I_TCPH") - 18  )/ Info("I_NUMFIXEDLANES") ) * lane - 1
  end
end

reaper.CF_SetTcpScroll( track, position )

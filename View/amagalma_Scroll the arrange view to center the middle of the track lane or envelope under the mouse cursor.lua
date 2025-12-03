-- @description Scroll the arrange view to center the middle of the track lane or envelope under the mouse cursor
-- @author amagalma
-- @version 1.01
-- @changelog Fix for when only one lane is visible and has the maximum size
-- @donation https://www.paypal.me/amagalma

if not reaper.CF_SetTcpScroll then
  return reaper.MB( "Please, install / update SWS.", "Missing CF_SetTcpScroll API", 0 )
end

if not reaper.JS_Window_FindChildByID then
  return reaper.MB( "Please, install JS_ReaScriptAPI", "Missing API", 0 )
end

local x, y = reaper.GetMousePosition()
local track, info = reaper.GetTrackFromPoint( x, y )

if not track then return end

local arrange = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 0x3E8 )
local arrange_height = select( 3, reaper.JS_Window_GetClientSize( arrange ) )

local function Info( str )
  return reaper.GetMediaTrackInfo_Value( track, str )
end

local position, half = 0, 0

if info == 1 then
  reaper.BR_GetMouseCursorContext()
  local env, isTakeEnvelope = reaper.BR_GetMouseCursorContext_Envelope()
  if not isTakeEnvelope then
    position = reaper.GetEnvelopeInfo_Value( env, "I_TCPY_USED" )
    half = reaper.GetEnvelopeInfo_Value( env, "I_TCPH_USED" ) // 2
  end
else
  local lane = info >> 8
  if Info("C_LANESCOLLAPSED") == 0 then
    local num_lanes = Info("I_NUMFIXEDLANES")
    local lane_height = ( Info("I_TCPH") - (num_lanes == 1 and 0 or 18)  ) / num_lanes
    position = lane_height * lane - 1
    half = lane_height // 2
  else
    half = Info("I_TCPH") // 2
  end
end

local mid = position + half - (arrange_height // 2)

reaper.CF_SetTcpScroll( track, mid )

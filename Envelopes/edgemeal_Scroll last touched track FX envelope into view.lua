-- @description Scroll last touched track FX envelope into view
-- @author Edgemeal
-- @version 1.01
-- @provides [windows] .
-- @donation Donate https://www.paypal.me/Edgemeal
-- @about
--   * Requires SWS and js_ReaScriptAPI extensions
--
--   1) If envelope for last touched Track FX parameter does not exist it is created.
--   2) Displays envelope in lane and scrolled into view/top of TCP.
--   3) Selects the envelope.

local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
if not retval then return end
local tr = reaper.CSurf_TrackFromID(tracknumber, false)
if not tr then return end -- Track FX only!
local env = reaper.GetFXEnvelope(tr, fxnumber, paramnumber, false)
if not env then
  env = reaper.GetFXEnvelope(tr, fxnumber, paramnumber, true)
  reaper.TrackList_AdjustWindows(false)
end
if env then
  local br_env = reaper.BR_EnvAlloc(env, false)
  local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
  reaper.BR_EnvSetProperties(br_env, true, true, armed, true, laneHeight, defaultShape, faderScaling)
  reaper.BR_EnvFree(br_env, true) 
  reaper.PreventUIRefresh(1)
  local arrange = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(),1000)
  reaper.JS_Window_SetScrollPos(arrange, "v",0)             -- reset scroll y
  local tr_y = reaper.GetMediaTrackInfo_Value(tr, 'I_TCPY') -- get env track y
  local env_y = reaper.GetEnvelopeInfo_Value(env, 'I_TCPY') -- get env y
  reaper.JS_Window_SetScrollPos(arrange, "v", tr_y + env_y) -- scroll env to top/into view
  reaper.SetCursorContext(2, env)                           -- select env
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  reaper.PreventUIRefresh(-1)
end

-- @description Toggle bypass or offline of selected FX in the focused FX chain window
-- @author cfillion
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > cfillion_Toggle bypass of selected FX in the focused FX chain window.lua
--   [main] . > cfillion_Toggle offline of selected FX in the focused FX chain window.lua
-- @link
--   https://cfillion.ca
--   Request post https://forum.cockos.com/showpost.php?p=2834699
-- @donation https://reapack.com/donate

local script_name = select(2, reaper.get_action_context()):match('([^/\\_]+)%.lua$')
local what = script_name:match('bypass') and 'Enabled' or 'Offline'
reaper.Undo_BeginBlock();
(function()
  local rv, track_id, item_id, take_id, fx_id, parm = reaper.GetTouchedOrFocusedFX(1)
  fx_id = fx_id & ~0xFFFFFF
  if not rv then return end
  local track = reaper.CSurf_TrackFromID(track_id + 1, false)
  local get, set, obj
  if item_id < 0 then
    which, obj = 'Track', track
  else
    local item = reaper.GetTrackMediaItem(track, item_id)
    local take = reaper.GetMediaItemTake(item, take_id)
    which, obj = 'Take', take
  end

  local get = reaper[which..'FX_Get'..what]
  local set = reaper[which..'FX_Set'..what]
  local chain = reaper.CF_GetFocusedFXChain()
  if not chain then return end
  local i = -1
  while true do
    i = reaper.CF_EnumSelectedFX(chain, i)
    if i < 0 then break end
    set(obj, fx_id|i, not get(obj, fx_id|i))
  end
end)()
reaper.Undo_EndBlock(script_name, 0)

-- @description Toggle visual spacer before or after selected tracks
-- @author cfillion
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > cfillion_Toggle visual spacer before selected tracks.lua
--   [main] . > cfillion_Toggle visual spacer after selected tracks.lua
-- @donation https://reapack.com/donate

local UNDO_STATE_TRACKCFG <const> = 1
local SCRIPT_NAME <const> = select(2, reaper.get_action_context()):match("([^/\\_]+)%.lua$")
local MODE_AFTER <const> = SCRIPT_NAME:match('after')

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
for i = 0, reaper.CountSelectedTracks(nil) - 1 do
  local track = reaper.GetSelectedTrack(nil, i)
  if MODE_AFTER then
    local id = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
    track = reaper.GetTrack(nil, id)
    if not track then break end
  end
  local spacer = reaper.GetMediaTrackInfo_Value(track, 'I_SPACER')
  reaper.SetMediaTrackInfo_Value(track, 'I_SPACER', spacer ~ 1)
end
reaper.Undo_EndBlock(SCRIPT_NAME, UNDO_STATE_TRACKCFG)
reaper.PreventUIRefresh(-1)

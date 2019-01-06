-- @description Reset TCP height of selected tracks to default
-- @author cfillion
-- @version 1.0
-- @link https://cfillion.ca
-- @donation https://paypal.me/cfillion

local UNDO_STATE_TRACKCFG = 1
local I_HEIGHTOVERRIDE = 'I_HEIGHTOVERRIDE'
local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

local didSomething = false

for i=0,reaper.CountSelectedTracks(0)-1 do
  local track = reaper.GetSelectedTrack(0, i)

  if reaper.GetMediaTrackInfo_Value(track, I_HEIGHTOVERRIDE) > 0 then
    if not didSomething then
      reaper.Undo_BeginBlock()
      didSomething = true
    end

    reaper.SetMediaTrackInfo_Value(track, I_HEIGHTOVERRIDE, 0)
  end
end

if didSomething then
  reaper.Undo_EndBlock(SCRIPT_NAME, UNDO_STATE_TRACKCFG)
  reaper.TrackList_AdjustWindows(true)
else
  reaper.defer(function() end)
end

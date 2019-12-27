-- @description Bypass all input FX for selected tracks
-- @author cfillion
-- @version 2.0
-- @changelog
--   Split the original script into three actions:
--
--   - Bypass all input FX for selected tracks
--   - Unbypass all input FX for selected tracks
--   - Toggle bypass all input FX for selected tracks (original behavior)
-- @provides
--   .
--   [main] . > cfillion_Unbypass all input FX for selected tracks.lua
--   [main] . > cfillion_Toggle bypass all input FX for selected tracks.lua
-- @link http://forum.cockos.com/showthread.php?t=185229
-- @about
--   This script provides three actions for bypassing all input FX on selected tracks at once:
--
--   - Bypass all input FX for selected tracks
--   - Unbypass all input FX for selected tracks
--   - Toggle bypass all input FX for selected tracks

local UNDO_STATE_FX = 2

local scriptName = ({reaper.get_action_context()})[2]:match('([^/\\_]+)%.lua$')
local toggleMode = scriptName:match('Toggle')
local enable = scriptName:match('Unbypass') ~= nil

reaper.Undo_BeginBlock()

for ti=0,reaper.CountSelectedTracks()-1 do
  local track = reaper.GetSelectedTrack(0, ti)
  for fi=0,reaper.TrackFX_GetRecCount(track) do
    fi = fi + 0x1000000

    if toggleMode then
      enable = not reaper.TrackFX_GetEnabled(track, fi)
    end

    reaper.TrackFX_SetEnabled(track, fi, enable)
  end
end

reaper.Undo_EndBlock(scriptName, UNDO_STATE_FX)

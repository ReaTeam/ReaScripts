-- @description Unselect hidden tracks (MCP and/or TCP)
-- @author cfillion
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > cfillion_Unselect tracks hidden in MCP.lua
--   [main] . > cfillion_Unselect tracks hidden in TCP.lua
--   [main] . > cfillion_Unselect tracks hidden in MCP and TCP.lua
-- @link cfillion.ca https://cfillion.ca
-- @donation Donate via PayPal https://paypal.me/cfillion
-- @about
--   This script provides three actions to unselect hidden selected tracks:
--
--   - cfillion_Unselect tracks hidden in MCP.lua
--   - cfillion_Unselect tracks hidden in TCP.lua
--   - cfillion_Unselect tracks hidden in MCP and TCP.lua

function enumSelectedTracksReverse()
  local i = reaper.CountSelectedTracks(0)
  return function()
    i = i - 1
    return reaper.GetSelectedTrack(0, i)
  end
end

local TCP = 1<<9
local MCP = 1<<10

local modes = {
  ['TCP'        ] = TCP,
  ['MCP'        ] = MCP,
  ['MCP and TCP'] = TCP|MCP,
}

local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local mode = modes[scriptName:match("in (.+)$")]
assert(mode, 'Invalid filename, cannot deduce what to do.')

reaper.Undo_BeginBlock()

for track in enumSelectedTracksReverse() do
  local _, state = reaper.GetTrackState(track)

  if state & mode == mode then
    reaper.SetTrackSelected(track, false)
  end
end

reaper.Undo_EndBlock(scriptName, 1)

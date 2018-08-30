-- @description Rename selected tracks from clipboard lines
-- @version 1.0
-- @author cfillion
-- @website
--   cfillion.ca https://cfillion.ca
--   Request Post https://forum.cockos.com/showpost.php?p=2029104
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Rename+selected+tracks+from+clipboard+lines

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local UNDO_STATE_TRACKCFG = 1
local clipboard, index = reaper.CF_GetClipboard(''), 0

if clipboard:len() < 1 or reaper.CountSelectedTracks(0) < 1 then
  reaper.defer(function() end) -- no undo point
end

reaper.Undo_BeginBlock()

for line in clipboard:gmatch("([^\r\n]*)[\r\n]*") do
  local track = reaper.GetSelectedTrack(0, index)
  if not track then break end

  reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', line, true)
  index = index + 1
end

reaper.Undo_EndBlock(script_name, UNDO_STATE_TRACKCFG)
